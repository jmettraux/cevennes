# frozen_string_literal: true

require 'csv'


module Cevennes

  VERSION = '1.4.0'

  class << self

    def diff(id, csv0, csv1, opts={})

      h0 = hajh('old', id, csv0, opts)
      h1 = hajh('new', id, csv1, opts)

      ks0 = h0.delete(:keys)
      ks1 = h1.delete(:keys)

      d =
        h0
          .collect { |k, v|
            v1 = h1[k]
            if v1 == nil then         [ '-', *v,   -1, nil ]
            elsif v1[1] == v[1] then  [ '=', *v, v[0], nil ]
            else                      [ '!', *v,  *v1 ]
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

      d = d.reject { |e| e[0] == '=' } if opts[:drop_equals]

      [ [ 'keys', *ks0, *ks1 ], [ 'stats', s ] ] + d
    end

    protected

    def strip(row)

      row.collect { |cell| cell.is_a?(String) ? cell.strip : cell }
    end

    DOWNCASE = lambda { |x| x.respond_to?(:downcase) ? x.downcase : x }
    IDENTITY = lambda { |x| x }

    # was named "hash", but since it shadowed a core method, let's use "hajh"
    #
    def hajh(version, id, csv, opts)

      d = opts[:ignore_key_case] ? DOWNCASE : IDENTITY
      did = d[id]

      csva = parse(csv, opts)
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

    def parse(csv, opts=nil)

      csv.is_a?(Array) ? csv :
      ::CSV.parse(reencode(csv, opts))
    end

    def reencode(s, opts)

      enc = opts ? opts[:encoding] : nil

      (enc ? [ enc ] : [ 'UTF-8', 'Windows-1252', 'ISO-8859-1' ])
        .each do |enc|
          s1 = s.dup.force_encoding(enc); next unless s1.valid_encoding?
          return s1.encode('UTF-8')
        rescue Encoding::UndefinedConversionError
          next
        end

      fail "failed to reencode #{(s.encoding rescue '(unknown encoding)')}"
    end
  end
end

