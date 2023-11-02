# "Five words" problem solver

## Info

This is a generalized solver for the five words problem discussed in [this video](https://www.youtube.com/watch?v=_-AfhLQfb6w). It is able to solve the problem for and combination of word count and letter count, for any language.

Its not the fastest solver, taking 1:45 to solve the problem for 5 six-letter words in the Russian dataset. It can crunch about `1925134645.78` iterations per second, but that number fluctuates with the dataset and settings.

## Algorithm

Words of the correct length from the dataset are loaded into memory, and pruned to remove words that themselves contain duplicate letters (eg. `test` contains the letter `t` twice, so its removed from the list and never checked)

Then every single word is encoded into a single integer, where each bit represents a letter. This step is basically instant.

eg.
```
00000
ABCDE

the word "BEAD" becomes:
11011
ABCDE
```

After this, every possible combination of words is iterated, eg.
`{ 1, 2, 3 }`, `{ 1, 2, 4 }`, `{ 1, 3, 4 }` etc...

During each iteration I do a bitwise OR over every single word in the set, combining the results

eg.

```
ABCDEFGH
10010000 (AD)
01100000 (BC)
00001010 (GE)
-----
11111010 = 6 (good)
```

Then I get the hamming weight of the resulting number, in this case `6`, if that hamming weight is equal to the number of unique letters wanted in the result sequence (`word length * word count`), then I know for a fact that set has no duplicate letters, since duplicate letters would overlap in the bitwise OR and the hamming weight would be less than `6` here.

eg.

```
ABCDEFGH
10010000 (AD)
01100000 (BC)
00010010 (DG)
-----
11110010 = 5 (bad, theres duplicate letters)
```

### Optimizations

To reduce duplicate iterations, I check the hamming weight at every bitwise OR in the sequence (i do one more bitwise OR per word in a set) and check "is there any duplicate letters yet"

If there is a duplicate letter in the sequence, then I know all remaining combinations containing that start with the current sequence are invalid, 

eg.

```
{ 1, 2, 3, 4, 5, 6 }
The bitwise OR of this set is done in the order of
sum <- 1 | 2
sum <- sum | 3
...

If i find after `sum | 3` that there is duplicates (by checking the hamming weight against what it should be at this step) I can skip every single set after that, eg i can skip:
{ 1, 2, 3, 4, 5, 7 }
{ 1, 2, 3, 4, 5, 8 }
{ 1, 2, 3, 4, 5, 9 }
{ 1, 2, 3, 4, 6, 7 }
{ 1, 2, 3, 4, 6, 8 }
{ 1, 2, 3, 4, 6, 9 }
...
And skip to the set
{ 1, 2, 4, 5, 6, 7 }

```

This reduces a 21 day runtime to 1:30, and makes my algorithm *actually* feasible to run on a single thread on a normal computer.

## Results

### Russian
Time: 1:30
```
settings: 5 words, 6 characters long
loaded 6252 words
pruned down to 3842 words
iterating through 6957844660224128 combinations
found set /брехун/взгляд/пьющий/съёмцы/эшафот/
found set /брюхан/вздеть/жгучий/пошляк/съёмцы/
found set /брюхан/вздеть/жгучий/пошляк/съёмцы/
found set /бункер/взгляд/пьющий/съёмцы/эшафот/
found set /бункер/взгляд/пьющий/съёмцы/эшафот/
found set /бучить/взгляд/пещной/съёмцы/хрюшка/
found set /бучить/взгляд/съёмцы/хрюшка/щепной/
found set /взгляд/жучить/пещной/съёмцы/хрюшка/
found set /взгляд/жучить/съёмцы/хрюшка/щепной/
found set /гвоздь/плюмаж/счётец/хрящик/шубный/
```

### Esperanto
Time: 0.669s
```
settings: 3 words, 5 characters long
loaded 3733 words
pruned down to 2432 words
iterating through 2394437760 combinations
found set /ambli/grupe/konst/
found set /ambli/konst/prude/
found set /baŭmi/grupe/konst/
found set /baŭmi/konst/prude/
found set /belga/furzi/konst/
found set /belga/konst/murdi/
found set /belga/konst/pruvi/
found set /belga/konst/pudri/
found set /belga/konst/ŝurci/
found set /bĵura/flegi/konst/
found set /bĵura/hejmi/konst/
found set /bĵura/helpi/konst/
found set /bĵura/jelpi/konst/
found set /bĵura/konst/milde/
found set /bĵura/konst/pledi/
found set /bĵura/konst/ŝveli/
found set /bĵura/konst/veldi/
...
```

## Running

Download zig `0.12.0-dev.1350+91e117697`

`zig build -Doptimize=ReleaseFast -Dlanguage=esperanto -Dword_count=3 -Dword_length=5 run`

`zig build -Doptimize=ReleaseFast -Dlanguage=russian -Dword_count=3 -Dword_length=5 run`