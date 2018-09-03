
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

pp d
    end
  end
end

