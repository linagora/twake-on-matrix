// Records one stageshow example as a 1920x1080 WebM, then prints the stage box.
// Usage (from ~/Developer/twake-chat-stageshow, Vite running on :5199):
//   EX=<example> node rec.cjs 1920 1200 <outDir> <durationMs>
// The window is 1200 high so the 1080 frame never shows a grey band; crop after.
const { chromium } = require(process.cwd() + '/node_modules/playwright-core')

;(async () => {
  const [w, h, out, dur] = [+process.argv[2], +process.argv[3], process.argv[4], +process.argv[5]]
  const example = process.env.EX || 'twake-chat'
  const browser = await chromium.launch({ channel: 'chrome' })
  const ctx = await browser.newContext({
    viewport: { width: w, height: h },
    recordVideo: { dir: out, size: { width: w, height: h } },
  })
  await ctx.addInitScript(() => {
    document.addEventListener('DOMContentLoaded', () => {
      const s = document.createElement('style')
      s.textContent =
        'html,body{margin:0;padding:0;background:#fff;overflow:hidden} #root,#example{width:1920px;height:1080px;margin:0;padding:0;display:grid;place-items:center}'
      document.head.appendChild(s)
    })
  })
  const page = await ctx.newPage()
  await page.goto('http://localhost:5199/?capture=' + example)
  await page.waitForSelector('#example')
  await page.evaluate(() => document.querySelector('#example').setAttribute('data-ss-fill', ''))
  await page.waitForTimeout(dur)
  console.log(JSON.stringify(await page.evaluate(() => document.querySelector('.ss-stage').getBoundingClientRect())))
  await ctx.close()
  await browser.close()
})()
