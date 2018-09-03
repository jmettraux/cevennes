
require 'csv'


module Cevennes

  VERSION = '0.9.0'

  class << self

    def diff(id, csv0, csv1)

      h0 = hash(id, csv0)
      h1 = hash(id, csv1)
    end

    protected

    def hash(id, csv)

      csva = ::CSV.parse(straighten(csv))
        .reject { |row| row.compact.empty? }
        .drop_while { |row| ! row.include?(id) }

      idi = csva[0].index(id)

      csva.inject({}) { |h, row|
        h[row[idi]] = deflate(row)
        h }
    end

    def deflate(row)

      ::CSV.generate(encoding: 'UTF-8') { |csv| csv << row }.strip
    end

    def straighten(s)

      #s = unzip(s) if s[0, 2] == 'PK'
        # no dependency on rubyzip

      %w[ Windows-1252 ISO-8859-1 UTF-8 ].each do |e|
        ss = s.force_encoding(e).encode('UTF-8') rescue nil
        break ss if ss
        nil
      end
    end
  end
end

