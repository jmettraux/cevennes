
#
# Specifying cevennes
#
# Mon Sep  3 12:00:30 JST 2018
#

require 'spec_helper'


describe Cevennes do

  describe '.diff' do

    it 'works' do

      cvs0 = File.read('spec/list0.csv')
      cvs1 = File.read('spec/list1.csv')

      d = Cevennes.diff('ISIN / Cusip', cvs0, cvs1)

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

      expect(
        d
      ).to eq([
        [ 'keys', [ 1, [ 'id', 'name', 'age' ] ],
                  [ 1, [ 'id', 'name', 'age' ] ] ],
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

      cvs0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      cvs1 = %{
id,name,age,city
0,John,33,Alexandria
1,Jean-Baptiste,44,Galileia
4,Matthew,20,Beth
      }.strip + "\n"

      d = Cevennes.diff('id', cvs0, cvs1)

      expect(
        d
      ).to eq([
        [ 'keys', [ 1, [ 'id', 'name', 'age' ] ],
                  [ 1, [ 'id', 'name', 'age', 'city' ] ] ],
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

      cvs0 = %{
XXXid,name,age
0,John,33
      }.strip + "\n"
      cvs1 = %{
id,name,age,city
0,John,33,Alexandria
      }.strip + "\n"

      expect {
        Cevennes.diff('id', cvs0, cvs1)
      }.to raise_error(
        IndexError, 'id "id" not found in old CSV'
      )
    end

    it 'returns nil if there is no id in the new CSV' do

      cvs0 = %{
id,name,age
1,Jean-Baptiste,43
      }.strip + "\n"
      cvs1 = %{
XXXid,name,age,city
1,Jean-Baptiste,44,Galileia
      }.strip + "\n"

      expect {
        Cevennes.diff('id', cvs0, cvs1)
      }.to raise_error(
        IndexError, 'id "id" not found in new CSV'
      )
    end

    it 'trims keys' do

      cvs0 = %{
id,name,age
0,John,33
1,Jean-Baptiste,43
3,Luke,21
      }.strip + "\n"
      cvs1 = %{
id, name,age , city , county
0,John,33,Alexandria,Yorkshire
1,Jean-Baptiste,44,Galileia,Lancashire
4,Matthew,20,Beth,Essex
      }.strip + "\n"

      d = Cevennes.diff('name', cvs0, cvs1)

      expect(
        d[0]
      ).to eq(
        [ 'keys',
          [ 1, %w[ id name age ] ],
          [ 1, %w[ id name age city county ] ] ]
      )
      expect(
        d[1]
      ).to eq(
        [ 'stats', { '!' => 2, '-' => 1, '+' => 1, 'l0' => 3, 'l1' => 3 } ],
      )
    end
  end
end

