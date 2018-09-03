
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

      expect(d.length).to eq(13)

      expect(
        d[1]
      ).to eq([
        'stats',
        { '=' => 8, '!' => 1, '-' => 1, '+' => 1, 'l0' => 9, 'l1' => 9 }
      ])

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
  end
end

