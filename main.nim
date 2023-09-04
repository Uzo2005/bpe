#[
    Implement the original bpe, then adapt it to nlp
]#

import strutils, sequtils, tables, sets, base64, sugar


const
    fileName = "bgCorpus.txt"
    rawText = readfile(fileName).strip
    rawCorpus = rawText.split.mapit(it.replace('\'', ' ').replace(" ", ""))
    vocabSize = 1000

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



var
    allChars = rawText.toOrderedSet
    vocab = collect(initOrderedTable):
        for i, c in allChars: {$c: i}
    newCorpus = initCountTable[seq[string]]()
    recentMerge: string
    merged: int

for word in rawCorpus:
    newCorpus.inc(word.toSeq.mapit($it))


let originalVocabLen = vocab.len

#start
while merged < (vocabSize - originalVocabLen):
    var
        currentVocabLen = vocab.len
        mostFrequent: string
        mergedNewCorpus = initCountTable[seq[string]]()
        pairFrequency = initCountTable[string]()

    for word, frequency in newCorpus:
        for i in 0..<word.len - 1:
            pairFrequency.inc(word[i..i+1].join, frequency)

    if pairFrequency.len == 0:
        echo "You Have Merged All The Words: "
        echo "  this suggests that your intended vocabsize is too much, reduce it to a value less than ", merged, " and try again"
        quit(1)

    mostFrequent = pairFrequency.largest.key

    if recentMerge == mostFrequent:
        echo """Looks like no merges left because """", mostfrequent, """" refused to merge in the previous round"""
        echo "this suggests that your intended vocabsize is too much, reduce it to a value less than ", merged, " and try again"
        break
        # quit(1)

    recentMerge = mostFrequent

    for word, frequency in newCorpus:
        let mergedWord = word.merge(mostFrequent)
        mergedNewCorpus.inc(mergedWord, frequency)
        # if mergedWord != word:
        #     echo "merging ", mostfrequent, " turns ", word, " into ", mergedWord


    vocab[mostFrequent] = currentVocabLen
    newCorpus = mergedNewCorpus
    echo "merged ", mostFrequent
    inc merged


#write the vocab to file in base64 encoding

# echo "----------------------"
# echo vocab
# echo "----------------------"

let bpeOutputFile = open("myBpeFile.bpe", fmWrite)

for subword, rank in vocab:
    bpeOutputFile.writeLine(subword.encode, " ", rank)

close(bpeOutputFile)
