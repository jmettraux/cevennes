
# cevennes

[![tests](https://github.com/jmettraux/cevennes/workflows/test/badge.svg)](https://github.com/jmettraux/cevennes/actions)
[![Gem Version](https://badge.fury.io/rb/fugit.svg)](http://badge.fury.io/rb/fugit)

Diffs CSVs by lines, focusing on a single ID


## usage

Given two CSV strings and an identifier name (a column name), cevennes may compute a diff:
```ruby
require 'cevennes'

cvs0 = %{
  id,name,age
  0,John,33
  1,Jean-Baptiste,43
  3,Luke,21
}.strip + "\n"
cvs1 = %{
  id,name,age
  0,John,33
  1,Jean-Baptiste,44
  4,Matthew,20
}.strip + "\n"

d = Cevennes.diff('id', cvs0, cvs1)

#d = Cevennes.diff('id', cvs0, cvs1, ignore_key_case: true)
  # when the key case should be ignored ("Id" == "id")
```

`d` will yield:
```ruby
[
  [ 'keys', 1, [ 'id', 'name', 'age' ],
            1, [ 'id', 'name', 'age' ] ],
  [ 'stats',
    { '=' => 1, '!' => 1, '-' => 1, '+' => 1,
      'l0' => 3, 'l1' => 3 } ],
  [ '=',  2, [ '0', 'John', '33'],
          2, nil ],
  [ '!',  3, [ '1', 'Jean-Baptiste', '43' ],
          3, [ '1', 'Jean-Baptiste', '44' ] ],
  [ '-',  4, [ '3', 'Luke', '21'],
         -1, nil ],
  [ '+', -1, nil,
          4, [ '4', 'Matthew', '20' ] ]
]
```
It's a list where the first entry is a recap of the keys used in the old and the new CSV strings (the integer is the line number (starting at 1) where the keys where found.

The second entry is a summary of the changes, altered `!` line count, removed `-` line count, added `+` line count, old length `l0`, new length `l1`, and unchanged `=` line count.

The remaining entries are the (non-)changes themselves, from line 1 to the end.


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

