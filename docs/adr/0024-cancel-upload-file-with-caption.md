# 24. Cancel upload file with caption

Date: 2024-08-19

## Status

Accepted

- Issue: [#1972](https://github.com/linagora/twake-on-matrix/issues/1972)

## Context

- The caption is sent anyway, there's also a weird upload preview that disappears after you reload the page.

## Decision
1. **Update logic for Cancelling Upload files with captions**
   - If the user uploads files with captions (on Web and mobile), update the logic for this case:
     - In the last element of the file upload list, add information about the caption. 
     - When the user cancels a file upload, check if the file has associated caption information, and remove both the file and the caption. 
     - If the file doesn’t have caption information, remove only the file.
   - Example:
     - User upload 3 files: [ file1, file2, file3].
     - User add a caption for upload files. => [ file1, file2, file3 (caption)].
     - And add an information of caption to last file. `file3` has an information.
     - If user cancel upload cancel randomly a file.
     - Check if the caption information is not null.
     - If the caption information is not null => remove both the file and the caption.
     - If the caption information is null => remove only the file.
     - If the user cancels the upload of `file1`, only `file1` is removed.
     - If the user cancels the upload of `file2`, only `file2` is removed..
     - If the user cancels the upload of `file3`, both `file3` and the caption are removed.

2. **Update UI/UX for Cancelling Upload**
   - Display a cancel upload icon during file upload and while receiving upload progress. 
   - If upload progress cannot be received, only display a loading icon and disable the cancel upload option.

## Consequences

- Cancel upload of media, the caption isn't sent either.
- There's no weird preview if I canceled upload