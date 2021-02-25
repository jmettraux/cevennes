# frozen_string_literal: true

require 'csv'


module Cevennes

  VERSION = '1.1.1'

  class << self

    def diff(id, csv0, csv1, opts={})

      h0 = hash('old', id, csv0, opts)
      h1 = hash('new', id, csv1, opts)

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

      [ [ 'keys', *ks0, *ks1 ], [ 'stats', s ] ] + d
    end

    protected

    def strip(row)

      row.collect { |cell| cell.is_a?(String) ? cell.strip : cell }
    end

    DOWNCASE = lambda { |x| x.respond_to?(:downcase) ? x.downcase : x }
    IDENTITY = lambda { |x| x }

    def hash(version, id, csv, opts)

      d = opts[:ignore_key_case] ? DOWNCASE : IDENTITY
      did = d[id]

      csva = ::CSV.parse(reencode(csv))
        .each_with_index.collect { |row, i| [ 1 + i, strip(row) ] }
        .reject { |i, row| row.compact.empty? }
        .drop_while { |i, row| ! row.find { |cell| d[cell] == did } }

      fail ::IndexError.new("id #{id.inspect} not found in #{version} CSV") \
        if csva.empty?

      csva[0][1] =
        opts[:ignore_key_case] ?
        csva[0][1].collect { |c| DOWNCASE[c] } :
        csva[0][1]

      idi = csva[0][1].index(did)

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

    ENCODINGS = %w[ Windows-1252 ISO-8859-1 UTF-8 ].freeze

    def reencode(s)

      #s = unzip(s) if s[0, 2] == 'PK'
        # no dependency on rubyzip

      #return s if s.encoding == Encoding::UTF_8
        # NO! have to force_encoding for UTF-8 as well!

      s = s.dup if s.frozen?

      ENCODINGS.each do |e|
        (return s.force_encoding(e).encode('UTF-8')) rescue nil
      end

      nil
    end
  end
end

