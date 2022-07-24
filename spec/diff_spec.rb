
#
# Specifying cevennes
#
# Mon Sep  3 12:00:30 JST 2018
#

require 'spec_helper'


describe Cevennes do

  describe '.diff' do

    it 'works' do

      csv0 = File.read('spec/list0.csv')
      csv1 = File.read('spec/list1.csv')

      d = Cevennes.diff('ISIN / Cusip', csv0, csv1)

      expect(d.length).to eq(14)

      expect(
        d[1]
      ).to eq([
        'stats',
        { '=' => 8, '!' => 1, '-' => 1, '+' => 2, 'l0' => 10, 'l1' => 11 }
      ])

      expect(
        d
          .select { |a| a[0].length == 1 }
          .collect { |a| [ a[0], a[1], a[3] ] }
      ).to eq(
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
          [ '+', -1, 28 ] ]
      )

      d2 = d[2]
      expect(d2[0]).to eq('=')
      expect(d2[1]).to eq(18)
      expect(d2[2][0, 4]).to eq([ nil, 'US037833BD17', 'Apple Inc', '2.000' ])
      expect(d2[3]).to eq(18)
      expect(d2[4]).to eq(nil)

      d3 = d[3]
      expect(d3[0]).to eq('!')
      expect(d3[1]).to eq(19)
      expect(d3[2][0, 4]).to eq([ nil, 'US037833BF64', 'Apple Inc', '2.700' ])
      expect(d3[2][8, 2]).to eq([ '98.6', '99.6' ])
      expect(d3[3]).to eq(19)
      expect(d3[4][0, 4]).to eq([ nil, 'US037833BF64', 'Apple Inc', '2.700' ])
      expect(d3[4][8, 2]).to eq([ '97.6', '98.6' ])
    end

    it 'works (vanilla example)' do

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

      expect(
        d
      ).to eq([
        [ 'keys', 1, [ 'id', 'name', 'age' ],
                  1, [ 'id', 'name', 'age' ] ],
        [ 'stats',
          { '=' => 1, '!' => 1, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
        [ '=', 2, [ '0', 'John', '33'], 2, nil ],
        [ '!', 3, [ '1', 'Jean-Baptiste', '43' ],
               3, [ '1', 'Jean-Baptiste', '44' ] ],
        [ '-', 4, [ '3', 'Luke', '21'], -1, nil ],
        [ '+', -1, nil, 4, [ '4', 'Matthew', '20' ] ]
      ])
    end

    it 'works (key alterations)' do

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

      expect(
        d
      ).to eq([
        [ 'keys', 1, [ 'id', 'name', 'age' ],
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
          4, [ '4', 'Matthew', '20', 'Beth' ] ]
      ])
    end

    it 'returns nil if there is no id in the old CSV' do

      csv0 = %{
XXXid,name,age
0,John,33
      }.strip + "\n"
      csv1 = %{
id,name,age,city
0,John,33,Alexandria
      }.strip + "\n"

      expect {
        Cevennes.diff('id', csv0, csv1)
      }.to raise_error(
        IndexError, 'id "id" not found in old CSV'
      )
    end

    it 'returns nil if there is no id in the new CSV' do

      csv0 = %{
id,name,age
1,Jean-Baptiste,43
      }.strip + "\n"
      csv1 = %{
XXXid,name,age,city
1,Jean-Baptiste,44,Galileia
      }.strip + "\n"

      expect {
        Cevennes.diff('id', csv0, csv1)
      }.to raise_error(
        IndexError, 'id "id" not found in new CSV'
      )
    end

    it 'trims keys' do

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

      expect(
        d[0]
      ).to eq(
        [ 'keys',
          1, %w[ id name age ],
          1, %w[ id name age city county ] ]
      )
      expect(
        d[1]
      ).to eq(
        [ 'stats', { '!' => 2, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
      )
    end

    it 'fails when key case is different' do

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

      expect {
        Cevennes.diff('id', csv0, csv1)
      }.to raise_error(
        IndexError, 'id "id" not found in new CSV'
      )
    end

    it 'works ignore_key_case: true' do

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

      expect(
        d
      ).to eq([
        [ 'keys', 1, [ 'id', 'name', 'age' ],
                  1, [ 'id', 'name', 'age' ] ],
        [ 'stats',
          { '=' => 1, '!' => 1, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
        [ '=', 2, [ '0', 'John', '33'], 2, nil ],
        [ '!', 3, [ '1', 'Jean-Baptiste', '43' ],
               3, [ '1', 'Jean-Baptiste', '44' ] ],
        [ '-', 4, [ '3', 'Luke', '21'], -1, nil ],
        [ '+', -1, nil, 4, [ '4', 'Matthew', '20' ] ]
      ])
    end

    it 'works ignore_key_case: true, take 2' do

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

      expect(
        d
      ).to eq([
        [ 'keys', 1, [ 'id', 'name', 'age' ],
                  1, [ 'id', 'name', 'age' ] ],
        [ 'stats',
          { '=' => 1, '!' => 1, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
        [ '=', 2, [ '0', 'John', '33'], 2, nil ],
        [ '!', 3, [ '1', 'Jean-Baptiste', '43' ],
               3, [ '1', 'Jean-Baptiste', '44' ] ],
        [ '-', 4, [ '3', 'Luke', '21'], -1, nil ],
        [ '+', -1, nil, 4, [ '4', 'Matthew', '20' ] ]
      ])
    end

    it 'works drop_equals: true' do

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

      expect(
        d
      ).to eq([
        ["keys", 1, ["id", "name", "age"], 1, ["id", "name", "age"]],
        ["stats", {"="=>2, "!"=>1, "-"=>1, "+"=>1, "l0"=>4, "l1"=>4}],
        ["!",
          3, ["1", "Jean-Baptiste", "43"],
          3, ["1", "Jean-Baptiste", "44"]],
        ["-",
          5, ["3", "Luke", "21"], -1, nil],
        ["+",
          -1, nil, 5, ["4", "Matthew", "20"]]
      ])
    end

    it 'works with various encodings' do

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

      expect(d.last).to eq([ '=', 5, [ '3', 'René', '21' ], 5, nil ])
    end

    it 'works with always parsed CSVs' do

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

      expect(d.last).to eq([ '=', 5, [ '3', 'René', '21' ], 5, nil ])
    end
  end
end

