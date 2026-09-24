
#
# Specifying cevennes
#
# Mon Sep  3 12:00:30 JST 2018
#


group Cevennes do

  group '.diff' do

    test 'works' do

      csv0 = File.read('test/list0.csv')
      csv1 = File.read('test/list1.csv')

      d = Cevennes.diff('ISIN / Cusip', csv0, csv1)

      assert_size d, 14

      assert(
        d[1],
        [
          'stats',
          { '=' => 8, '!' => 1, '-' => 1, '+' => 2, 'l0' => 10, 'l1' => 11 }
        ])

      assert(
        d
          .select { |a| a[0].length == 1 }
          .collect { |a| [ a[0], a[1], a[3] ] },
        [ [ '=', 18, 18 ],
          [ '!', 19, 19 ],
          [ '=', 20, 20 ],
          [ '=', 21, 21 ],
          [ '=', 22, 22 ],
          [ '+', -1, 22 ],
          [ '=', 23, 23 ],
          [ '=', 24, 24 ],
          [ '-', 25, -1 ],
          [ '=', 26, 26 ],
          [ '=', 27, 27 ],
          [ '+', -1, 28 ] ])

      d2 = d[2]
      assert d2[0], '='
      assert d2[1], 18
      assert d2[2][0, 4], [ nil, 'US037833BD17', 'Apple Inc', '2.000' ]
      assert d2[3], 18
      assert d2[4], nil

      d3 = d[3]
      assert d3[0], '!'
      assert d3[1], 19
      assert d3[2][0, 4], [ nil, 'US037833BF64', 'Apple Inc', '2.700' ]
      assert d3[2][8, 2], [ '98.6', '99.6' ]
      assert d3[3], 19
      assert d3[4][0, 4], [ nil, 'US037833BF64', 'Apple Inc', '2.700' ]
      assert d3[4][8, 2], [ '97.6', '98.6' ]
    end

    test 'works (vanilla example)' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      csv1 = %{
id,name,age
0,John,33
1,Jean-Baptiste,44
4,Matthew,20
      }.strip + "\n"

      d = Cevennes.diff('id', csv0, csv1)

      assert(
        d,
        [ [ 'keys', 1, [ 'id', 'name', 'age' ],
                    1, [ 'id', 'name', 'age' ] ],
          [ 'stats',
            { '=' => 1, '!' => 1, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
          [ '=', 2, [ '0', 'John', '33'], 2, nil ],
          [ '!', 3, [ '1', 'Jean-Baptiste', '43' ],
                 3, [ '1', 'Jean-Baptiste', '44' ] ],
          [ '-', 4, [ '3', 'Luke', '21'], -1, nil ],
          [ '+', -1, nil, 4, [ '4', 'Matthew', '20' ] ] ])
    end

    test 'works (key alterations)' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      csv1 = %{
id,name,age,city
0,John,33,Alexandria
1,Jean-Baptiste,44,Galileia
4,Matthew,20,Beth
      }.strip + "\n"

      d = Cevennes.diff('id', csv0, csv1)

      assert(
        d,
        [ [ 'keys', 1, [ 'id', 'name', 'age' ],
                    1, [ 'id', 'name', 'age', 'city' ] ],
          [ 'stats',
            { '!' => 2, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
          [ '!',
            2, ['0', 'John', '33' ],
            2, ['0', 'John', '33', 'Alexandria' ] ],
          [ '!',
            3, [ '1', 'Jean-Baptiste', '43' ],
            3, [ '1', 'Jean-Baptiste', '44', 'Galileia' ] ],
          [ '-',
            4, [ '3', 'Luke', '21' ],
            -1, nil ],
          [ '+',
            -1, nil,
            4, [ '4', 'Matthew', '20', 'Beth' ] ] ])
    end

    test 'returns nil if there is no id in the old CSV' do

      csv0 = %{
XXXid,name,age
0,John,33
      }.strip + "\n"
      csv1 = %{
id,name,age,city
0,John,33,Alexandria
      }.strip + "\n"

      assert_error(
        lambda { Cevennes.diff('id', csv0, csv1) },
        IndexError, 'id "id" not found in old CSV')
    end

    test 'returns nil if there is no id in the new CSV' do

      csv0 = %{
id,name,age
1,Jean-Baptiste,43
      }.strip + "\n"
      csv1 = %{
XXXid,name,age,city
1,Jean-Baptiste,44,Galileia
      }.strip + "\n"

      assert_error(
        lambda { Cevennes.diff('id', csv0, csv1) },
        IndexError, 'id "id" not found in new CSV')
    end

    test 'trims keys' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      csv1 = %{
id, name,age , city , county
0,John,33,Alexandria,Yorkshire
1,Jean-Baptiste,44,Galileia,Lancashire
4,Matthew,20,Beth,Essex
      }.strip + "\n"

      d = Cevennes.diff('name', csv0, csv1)

      assert(
        d[0],
        [ 'keys',
          1, %w[ id name age ],
          1, %w[ id name age city county ] ])
      assert(
        d[1],
        [ 'stats', { '!' => 2, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ])
    end

    test 'fails when key case is different' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      csv1 = %{
Id,Name,Age
0,John,33
1,Jean-Baptiste,44
4,Matthew,20
      }.strip + "\n"

      assert_error(
        lambda { Cevennes.diff('id', csv0, csv1) },
        IndexError, 'id "id" not found in new CSV')
    end

    test 'works ignore_key_case: true' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      csv1 = %{
Id,Name,Age
0,John,33
1,Jean-Baptiste,44
4,Matthew,20
      }.strip + "\n"

      d = Cevennes.diff('id', csv0, csv1, ignore_key_case: true)

      assert(
        d,
        [ [ 'keys', 1, [ 'id', 'name', 'age' ],
                    1, [ 'id', 'name', 'age' ] ],
          [ 'stats',
            { '=' => 1, '!' => 1, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
          [ '=', 2, [ '0', 'John', '33'], 2, nil ],
          [ '!', 3, [ '1', 'Jean-Baptiste', '43' ],
                 3, [ '1', 'Jean-Baptiste', '44' ] ],
          [ '-', 4, [ '3', 'Luke', '21'], -1, nil ],
          [ '+', -1, nil, 4, [ '4', 'Matthew', '20' ] ] ])
    end

    test 'works ignore_key_case: true, take 2' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      csv1 = %{
Id,Name,Age
0,John,33
1,Jean-Baptiste,44
4,Matthew,20
      }.strip + "\n"

      d = Cevennes.diff('Id', csv0, csv1, ignore_key_case: true)

      assert(
        d,
        [ [ 'keys', 1, [ 'id', 'name', 'age' ],
                    1, [ 'id', 'name', 'age' ] ],
          [ 'stats',
            { '=' => 1, '!' => 1, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
          [ '=', 2, [ '0', 'John', '33'], 2, nil ],
          [ '!', 3, [ '1', 'Jean-Baptiste', '43' ],
                 3, [ '1', 'Jean-Baptiste', '44' ] ],
          [ '-', 4, [ '3', 'Luke', '21'], -1, nil ],
          [ '+', -1, nil, 4, [ '4', 'Matthew', '20' ] ] ])
    end

    test 'works drop_equals: true' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
2,Vladimir,30
3,Luke,21
      }.strip + "\n"
      csv1 = %{
id,name,age
0,John,33
1,Jean-Baptiste,44
2,Vladimir,30
4,Matthew,20
      }.strip + "\n"

      d = Cevennes.diff('id', csv0, csv1, drop_equals: true)

      assert(
        d,
        [
          ["keys", 1, ["id", "name", "age"], 1, ["id", "name", "age"]],
          ["stats", {"="=>2, "!"=>1, "-"=>1, "+"=>1, "l0"=>4, "l1"=>4}],
          ["!",
            3, ["1", "Jean-Baptiste", "43"],
            3, ["1", "Jean-Baptiste", "44"]],
          ["-",
            5, ["3", "Luke", "21"], -1, nil],
          ["+",
            -1, nil, 5, ["4", "Matthew", "20"]] ])
    end

    test 'works with various encodings' do

      csv0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
3,René,21
      }.strip + "\n"
      csv1 = %{
id,name,age
0,John,33
1,Jean-Baptiste,44
2,Matthew,20
3,René,21
      }.strip + "\n"

      csv0 = csv0.encode('Windows-1252').freeze
      csv1 = csv1.encode('ISO-8859-1').freeze

      d = Cevennes.diff('Id', csv0, csv1, ignore_key_case: true)

      assert d.last, [ '=', 5, [ '3', 'René', '21' ], 5, nil ]
    end

    test 'works with always parsed CSVs' do

      csv0 = CSV.parse(%{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
3,René,21
      }.strip + "\n")
      csv1 = CSV.parse(%{
id,name,age
0,John,33
1,Jean-Baptiste,44
2,Matthew,20
3,René,21
      }.strip + "\n")

      d = Cevennes.diff('id', csv0, csv1)

      assert d.last, [ '=', 5, [ '3', 'René', '21' ], 5, nil ]
    end

    test 'works when a column is added' do

      csv0 = CSV.parse(%{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
3,René,21
      }.strip + "\n")
      csv1 = CSV.parse(%{
id,name,age,nick
0,John,33,Jack
1,Jean-Baptiste,44,Bat
2,Matthew,20,Matt
3,René,21,Ren
      }.strip + "\n")

      d = Cevennes.diff('id', csv0, csv1)

      assert(
        d,
        [["keys", 1, ["id", "name", "age"], 1, ["id", "name", "age", "nick"]],
         ["stats", {"!"=>3, "+"=>1, "l0"=>3, "l1"=>4}],
         ["!", 2, ["0", "John", "33"], 2, ["0", "John", "33", "Jack"]],
         ["!",
          3,
          ["1", "Jean-Baptiste", "43"],
          3,
          ["1", "Jean-Baptiste", "44", "Bat"]],
         ["+", -1, nil, 4, ["2", "Matthew", "20", "Matt"]],
         ["!", 5, ["3", "René", "21"], 5, ["3", "René", "21", "Ren"]]])
    end

    test 'works when a column is removed' do

      csv0 = CSV.parse(%{
id,name,age,nick
0,John,33,Jack
1,Jean-Baptiste,44,Bat
2,Matthew,20,Matt
3,René,21,Ren
      }.strip + "\n")
      csv1 = CSV.parse(%{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
3,René,21
      }.strip + "\n")

      d = Cevennes.diff('id', csv0, csv1)

      assert(
        d,
        [["keys", 1, ["id", "name", "age", "nick"], 1, ["id", "name", "age"]],
         ["stats", {"!"=>3, "-"=>1, "l0"=>4, "l1"=>3}],
         ["!", 2, ["0", "John", "33", "Jack"], 2, ["0", "John", "33"]],
         ["!",
          3,
          ["1", "Jean-Baptiste", "44", "Bat"],
          3,
          ["1", "Jean-Baptiste", "43"]],
         ["-", 4, ["2", "Matthew", "20", "Matt"], -1, nil],
         ["!", 5, ["3", "René", "21", "Ren"], 5, ["3", "René", "21"]]])
    end
  end
end

