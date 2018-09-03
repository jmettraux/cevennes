
require 'csv'


module Cevennes

  VERSION = '0.9.0'

  class << self

    def diff(id, csv0, csv1)

      h0 = hash(id, csv0)
      h1 = hash(id, csv1)

      ks0 = h0.delete(:keys)
      ks1 = h1.delete(:keys)

      d =
        h0
          .collect { |k, v|
            v1 = h1[k]
            if v1 == v
              [ '=', v, nil ]
            else
              [ v1 == nil ? '-' : '!', v, v1 ]
            end }
          .compact +
        (h1.keys - h0.keys)
          .collect { |k|
            v = h1[k]
            [ '+', nil, h1[k] ] }

      s = d.inject({}) { |h, (a, _, _)| h[a] = (h[a] || 0) + 1; h }
      s['l0'] = h0.length - 1
      s['l1'] = h1.length - 1

      [ [ 'keys', ks0, ks1 ], [ 'stats', s ] ] + d
    end

    protected

    def hash(id, csv)

      csva = ::CSV.parse(reencode(csv))
        .reject { |row| row.compact.empty? }
        .drop_while { |row| ! row.include?(id) }

      i = csva[0].index(id)

      csva[1..-1]
        .inject({ keys: csva[0] }) { |h, row|
          if row.compact.length > 1
            k = row[i]
            h[k] = row if k
          end
          h }
    end

    #def deflate(row)
    #  ::CSV.generate(encoding: 'UTF-8') { |csv| csv << row }.strip
    #end

    def reencode(s)

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
