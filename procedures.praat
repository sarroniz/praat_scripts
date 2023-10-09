# Procedures 
# 
##########################################################################

procedure getFiles: .dir$, .ext$
    .obj = Create Strings as file list: "files", .dir$ + "/*" + .ext$
    .length = Get number of strings

    for .i to .length
        .fname$ = Get string: .i
        .files$ [.i] = .dir$ + "/" + .fname$

    endfor

    removeObject: .obj

endproc

##########################################################################

procedure getTextGrid: .soundfile$
    .path$ = replace$: .soundfile$, sound_file_extension$, ".TextGrid", 0
    .textgrid = Read from file: .path$

    endif

endproc

##########################################################################

procedure splitstring: .string$, .sep$
    .strLen = 0
    repeat
        .sepIndex = index (.string$, .sep$)
        if .sepIndex <> 0
            .value$ = left$ (.string$, .sepIndex - 1)
            .string$ = mid$ (.string$, .sepIndex + 1, 10000)
        else
            .value$ = .string$
        endif
        .strLen = .strLen + 1
        .array$[.strLen] = .value$
    until .sepIndex = 0
endproc