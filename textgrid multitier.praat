# Santi Arroniz, adapted from Scott Seyfarth
# This Praat script takes a folder of sound files and for each sound
# file, the script creates a new TextGrid with the annotation tiers that you
# list in the settings window, then opens that TextGrid along with its
# accompanying sound file. The number of tiers will correspond with the number 
# of tier names provided. The script pauses while you create annotations for
# the sound file. When you are done creating annotations, press "OK" in the
# pop-up window to save the TextGrid to a file with the same filename as the
# sound file plus a ".TextGrid" extension. After saving the file, the script
# moves on to the next sound file in the folder.


form Settings
    sentence Interval_tiers Mary John
    sentence Point_tiers bell
    optionmenu If_TextGrid_already_exists: 1
        option skip the sound file
        option create a TextGrid with a different filename
        option open and edit the existing TextGrid
    word Sound_file_extension .wav
    sentence Filename_initial_substring_(optional)
    comment Press OK to choose a directory of sound files to annotate.

endform

directory$ = chooseDirectory$: "Choose a directory with 'sound_file_extension$'
... files to annotate."
@getFiles: directory$, sound_file_extension$

tiers$ = interval_tiers$ + " " + point_tiers$

for i to getFiles.length
    soundfile = Read from file: getFiles.files$ [i]

    @getTextGrid: getFiles.files$ [i]

    if !fileReadable (getTextGrid.path$) or if_TextGrid_already_exists > 1
        selectObject: soundfile, getTextGrid.textgrid
        View & Edit

        beginPause: "Annotation"
            comment: "Press OK when done to save."

        endPause: "OK", 0

        selectObject: getTextGrid.textgrid
        Save as text file: getTextGrid.path$

        removeObject: getTextGrid.textgrid

    endif

    removeObject: soundfile

endfor

procedure getTextGrid: .soundfile$
    .path$ = replace$: .soundfile$, sound_file_extension$, ".TextGrid", 0

    if !fileReadable: .path$
        .textgrid = To TextGrid: tiers$, point_tiers$

    elif if_TextGrid_already_exists == 2
        .textgrid = To TextGrid: tiers$, point_tiers$
        .default$ = mid$: .path$, rindex (.path$, "/") + 1, length (.path$)
        .default$ = replace$: .default$, sound_file_extension$, ".TextGrid", 1

        .path$ = chooseWriteFile$: "TextGrid already exists in this directory. 
        ... Choose where to save the new TextGrid.", .default$

    elif if_TextGrid_already_exists == 3
        .textgrid = Read from file: .path$

    endif

endproc

procedure getFiles: .dir$, .ext$
    .obj = Create Strings as file list: "files", .dir$ + "/*" + .ext$
    .length = Get number of strings

    for .i to .length
        .fname$ = Get string: .i
        .files$ [.i] = .dir$ + "/" + .fname$

    endfor

    removeObject: .obj

endproc