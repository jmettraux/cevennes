
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

      expect(d[2][0]).to eq('=')
      expect(d[2][1][0, 4]).to eq([ nil, 'US037833BD17', 'Apple Inc', '2.000' ])
      expect(d[2][2]).to eq(nil)

      expect(d[3][0]).to eq('!')
      expect(d[3][1][0, 4]).to eq([ nil, 'US037833BF64', 'Apple Inc', '2.700' ])
      expect(d[3][1][8, 2]).to eq([ '98.6', '99.6' ])
      expect(d[3][2][0, 4]).to eq([ nil, 'US037833BF64', 'Apple Inc', '2.700' ])
      expect(d[3][2][8, 2]).to eq([ '97.6', '98.6' ])

      expect(
        d[1]
      ).to eq([
        'stats',
        { '=' => 8, '!' => 1, '-' => 1, '+' => 1, 'l0' => 9, 'l1' => 9 }
      ])
    end
  end
end

