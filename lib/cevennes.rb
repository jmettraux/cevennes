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
            if v1 == nil         then [ '-', *v,   -1, nil ]
            elsif v1[1] == v[1]  then [ '=', *v, v[0], nil ]
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

    def to_pretty_s(diff, opts={})

      fail ArgumentError.new("to_pretty_s() expects a diff array") \
        unless is_diff_array?(diff)

      drop_eq = !! (opts[:drop_equals] || opts[:drop_eq])

      c =
        opts[:no_colours] || opts[:no_colors] ||
        opts[:no_colour] || opts[:no_color] ?
          Colorato.no_colours :
          Colorato.colour_if_supported

      cml = opts[:cell_max_len] || opts[:cell_maxlen] || 28

      _, kl0, ks0, kl1, ks1 = diff[0]
      _, stats = diff[1]

      dis = diff[2..-1]

      lnl = dis
        .inject([]) { |a, di| a << di[1].to_s.length << di[3].to_s.length; a }
        .max

      o = StringIO.new

      o << c.dg << "# diff\n" << c.rs

      o << "\n* length: #{diff.length}\n"
      o << "\n"

      o << c.dg << "## keys\n\n" << c.rs

      o << "```\n"
      o << "### ks0\n"
      o << (' ' * (lnl + 3)) << "# line: #{kl0}, count: #{ks0.size}\n"
      o << render_row(
        #ks0, ck: true, rn: kl0, colours: c, bc: c.dark_gray, indent: lnl + 3)
        ks0, ck: true, colours: c, bc: c.dark_gray, indent: lnl + 3, cml: cml)
      o << "\n### ks1\n"
      o << c.rs << (' ' * (lnl + 3)) << "# line: #{kl1}, count: #{ks1.size}\n"
      if ks1 == ks0
        o << c.dg << (' ' * (lnl + 3)) << "# (identical)\n" << c.rs
      else
        o << render_row(
          #ks1, ck: true, rn: kl1, colours: c, indent: lnl + 3) << "\n"
          ks1, ck: true, colours: c, indent: lnl + 3, cml: cml) << "\n"
      end
      o << "```\n\n"

      o << c.dg << "## stats\n\n" << c.rs
      o << "```\n  " << stats.inspect << "\n```\n\n"

      o << c.dg << "## diffs\n\n"
      o << "```\n"

      diff[2..-1].each do |di|

        next if drop_eq && (di[0] == '=')

        bc =
          case di[0]
          when '+' then c.green
          when '-' then c.red
          else c.dg; end
        o << bc

        lnl1 = lnl + 3
        os = { indent: lnl1, ck: true, colours: c, bc: bc, cml: cml }

        r0 = di[2] ? render_row(di[2], os) : ' ' * (lnl1)
        r1 = di[4] ? render_row(di[4], os.merge(vs: di[2])) : ' ' * (lnl1)

        o << di[0] << " %#{lnl}d " % di[1] << r0.lstrip << "\n"
        o << ' ' << " %#{lnl}d " % di[3] << r1.lstrip << "\n"

        o << c.rs
      end
      o << "```\n"

      o << c.dg << "\n## done |:." << c.rs

      o.string
    end

    def is_diff_array?(x)

      return false unless x.is_a?(Array)
      return false unless x.length > 1
      return false unless x.all? { |e| e.is_a?(Array) }
      return false unless x[0][0] == 'keys'
      return false unless x[1][0] == 'stats'
      true
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

    require 'io/console'

    def term_width

      w =
        ENV['COLUMNS'] ||
        ($stdout.winsize[1] rescue nil) ||
        (IO.console.winsize[1] rescue nil) ||
        (`tput cols`.to_i rescue nil) ||
        (`stty size`.split[1].to_i rescue nil)

      w.is_a?(Integer) && w > 0 ? w : 80
    end

    def render_row(row, opts={})

      c = opts[:colours] || Colorato.no_colours
      bc = opts[:base_colour] || opts[:bc] || ''

      rs = c.reset + bc

      indent = opts[:indent] || 0
      ck = opts[:col_keys] || opts[:ck]

      rn = opts[:row_number] || opts[:rn]
      rn = rn.to_s if rn

      cml = opts[:cml] || 28

      r0 = opts[:vs]

      ni = ' ' * indent

      tw = term_width - 1
      o = StringIO.new

      line = ni + bc + '[ '
      llen = Colorato.no_colour_length(line)
        #
      row.each_with_index do |cell, i|

        id = (ck ? xelcol(1 + i) : '') + (rn ? rn : '') + (ck || rn ? ' ' : '')
        id = c.rs + c.light_gray + id + rs if id.length > 0

        t = cell.is_a?(String) ? Colorato.truncate_string(cell, cml, '…') : cell
        ce = t.inspect
        ce = c.rs + c.yellow + ce + rs if r0 && cell != r0[i]

        cl = id + ce + ', '
        clen = Colorato.no_colour_length(cl)

        if indent + llen + clen > tw
          o << line << "\n"
          line = ni + '  '
          llen = line.length
        end
        line += cl
        llen += clen
      end
      o << line << ']'

      o.string
    end

    def xelcol(n)

      r = []
      while n > 0; n -= 1; r.unshift(('A'.ord + (n % 26)).chr); n /= 26; end

      r.join
    end
  end
end

