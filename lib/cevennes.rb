
require 'csv'


module Cevennes

  VERSION = '0.13.0'

  class << self

    def diff(id, csv0, csv1)

      h0 = hash('old', id, csv0)
      h1 = hash('new', id, csv1)

      ks0 = h0.delete(:keys)
      ks1 = h1.delete(:keys)

      d =
        h0
          .collect { |k, v|
            v1 = h1[k]
            if v1 == nil
              [ '-', *v, -1, nil ]
            elsif v1[1] == v[1]
              [ '=', *v, v[0], nil ]
            else
              [ '!', *v, *v1 ]
            end }

      (h1.keys - h0.keys)
        .collect { |k| h1[k] }
        .reverse
        .each { |lnum, line|
          i = d.index { |a, _, _, l1, _| l1 > lnum } || d.length
          d.insert(i, [ '+', -1, nil, lnum, line ]) }

      s = d.inject({}) { |h, (a, _, _)| h[a] = (h[a] || 0) + 1; h }
      s['l0'] = h0.length
      s['l1'] = h1.length

      [ [ 'keys', ks0, ks1 ], [ 'stats', s ] ] + d
    end

    protected

    def strip(row)

      row.collect { |cell| cell.is_a?(String) ? cell.strip : cell }
    end

    def hash(version, id, csv)

      csva = ::CSV.parse(reencode(csv))
        .each_with_index.collect { |row, i| [ 1 + i, strip(row) ] }
        .reject { |i, row| row.compact.empty? }
        .drop_while { |i, row| ! row.include?(id) }

      fail ::IndexError.new("id #{id.inspect} not found in #{version} CSV") \
        if csva.empty?

      idi = csva[0][1].index(id)

      csva[1..-1]
        .inject({ keys: csva[0] }) { |h, (i, row)|
          if row.compact.length > 1
            k = row[idi]
            h[k] = [ i, row ] if k
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

