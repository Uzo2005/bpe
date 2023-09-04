import strutils, sequtils, tables, base64
const bpeFilename = "myBpeFile.bpe"

var 
    subwordToRank: OrderedTable[string, int]
    rankToSubword: OrderedTable[int, string]
    

func merge*(s: seq[string], p: string): seq[string] =
    if p.len > s.join.len:
        return s
    iterator pairs(s: seq[string], n: int): string =
        for i in 0..<s.len:
            var nWindow: string
            if i >= s.len - n:
                var slider: int
                while nWindow.len < n:
                    if i+slider > s.len-1: #avoiding a potential index overflow
                        nwindow = s[i]
                        break
                    else:
                        nWindow.add(s[i+slider])
                    if nWindow.len == n:
                        break
                    elif nWindow.len > n and s[i].len < n and (i - slider != 0):#this means the last index added caused a "pair overflow"
                        # debugecho "s: ", s, " i: ", i, " slider: ", slider, " nwindow: ", nwindow, " n: ", n
                        let lenOfLastIndex = s[i + slider-1].len
                        nWindow.setLen(nWindow.len - lenOfLastIndex)
                        if nWindow.len < n:
                            nWindow = s[i]
                        break
                    inc slider
            else:
                var slider:int
                while nWindow.len < n:
                    nWindow.add(s[i+slider])
                    if nWindow.len > n:#this means the last index added caused a "pair overflow"
                        let lenOfLastIndex = s[i + slider].len
                        nWindow.setLen(nWindow.len - lenOfLastIndex)
                        if nWindow.len < n:
                            nWindow = s[i]
                        break
                    inc slider

            yield nWindow
           
    let listOfPairs = pairs(s, p.len).toseq

    var skipNext: int

    for index, pair in listOfPairs:
        #the pairs to be acted on can only contain entries of length: p.len
        if skipNext != 0 and index != 0:
            dec skipNext
            continue
        if pair == p:
            result.add(p)

            for j in 1..p.len - 1:
                if index + j < s.len:
                    if s[index + j].len + s[index].len == p.len:
                        inc skipNext
                        break
            
        else:
            result.add(s[index])




for line in bpeFilename.lines:
    let 
        linecontent = line.split(" ")
        subword = decode(linecontent[0])
        rank = parseInt(linecontent[1])

    subwordToRank[subword] = rank
    rankToSubword[rank] = subword

proc encode(s: string): seq[int] =
    var 
        temp = s.toseq.mapit($it)

    while true:
        var
            wordPairs = zip(temp[0..^2], temp[1..^1]).mapit(it[0] & it[1])
            pairFound: bool

        for index, pair in wordPairs:
            if subwordToRank.hasKey(pair):
                # echo "Pair: ", pair, " found for ", temp, " with pairs: ", wordPairs
                pairFound = true
                temp = temp.merge(pair)

        if not(pairFound):
            break

    for subword in temp:
        result.add(subwordToRank[subword])

proc decode(n: int): string =
    result = rankToSubword[n]

proc decode(n: seq[int]): string =
    for num in n:
        result.add(rankToSubword[num])


echo decode(encode("television is what I love watching"))

for word in encode("claypant"):
    echo decode(word), " is ", word
