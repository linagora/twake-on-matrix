const repoName = 'element-x-ios';
const href = `https://github.com/vector-im/${repoName}/archive`;
const zipFile = 'main.zip';

const source = `${href}/${zipFile}`;

const extractEntryTo = `${repoName}-main/`;

const outputDir = `./`;

const readYamlFile = require('read-yaml-file')
const fs = require('fs');
const request = require('request');
const admZip = require('adm-zip');
const { exec } = require("child_process");

const main = async () => {
    try {
        console.log('start downloading')
        await download(source, zipFile)
        console.log('finished downloading');

        var zip = new admZip(zipFile);
        console.log('start unzip');
        zip.extractEntryTo(extractEntryTo, outputDir, true, true);
        console.log('finished unzip');
        
        const dirname = `${outputDir}${extractEntryTo}NSE/SupportingFiles`
        const data = await readYamlFile(`${dirname}/target.yml`)
        const sources = data.targets.NSE.sources.map(source => source.path)

        console.log('copying NSE files')
        const ignoreSources = ['../SupportingFiles']

        sources
        .filter(source => !ignoreSources.includes(source))
        .forEach(source => {
            fs.cpSync(`${dirname}/${source}`, `../../ios/NSE/${source.split('/').pop()}`, { recursive: true })
        })

        console.log('apply patch')
        exec('cd ../../ && git apply scripts/patchs/element-x-nse-fix.patch')

        console.log('copying DesignKit files')
        fs.cpSync(`${outputDir}${extractEntryTo}DesignKit`, `../../ios/NSE/DesignKit`, { recursive: true });

        console.log('clean up')
        fs.unlinkSync(zipFile)
        fs.rmSync(extractEntryTo, { recursive: true })

        console.log('done')
    } catch (error) {
        console.log(error);
    }
}

const download = (url, output) => new Promise((resolve, reject) => {
    request
        .get(url)
        .on('error', function (error) {
            reject(error)
        })
        .pipe(fs.createWriteStream(output))
        .on('finish', function () {
            resolve()
        });
})

main()