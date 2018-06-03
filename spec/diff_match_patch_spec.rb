require "spec_helper"

RSpec.describe String do
  describe "#substring" do
    it "should be M" do
      expect("Mozilla".substring(0, 1)).to match("M")
    end

    it "should be M" do
      expect("Mozilla".substring(1, 0)).to match("M")
    end

    it "should be Mozill" do
      expect("Mozilla".substring(0, 6)).to match("Mozill")
    end

    it "should be lla" do
      expect("Mozilla".substring(4)).to match("lla")
    end

    it "should be lla" do
      expect("Mozilla".substring(4, 7)).to match("lla")
    end

    it "should be lla" do
      expect("Mozilla".substring(7, 4)).to match("lla")
    end

    it "should be Mozilla" do
      expect("Mozilla".substring(0, 7)).to match("Mozilla")
    end

    it "should be Mozilla" do
      expect("Mozilla".substring(0, 10)).to match("Mozilla")
    end
  end

  describe "#index_of" do
    it "should be 0" do
      expect("Blue Whale".index_of("Blue")).to match(0)
    end

    it "should be -1" do
      expect("Blue Whale".index_of("Blute")).to match(-1)
    end

    it "should be 5" do
      expect("Blue Whale".index_of("Whale", 0)).to match(5)
    end

    it "should be 5" do
      expect("Blue Whale".index_of("Whale", 5)).to match(5)
    end

    it "should be -1" do
      expect("Blue Whale".index_of('Whale', 7)).to match(-1)
    end

    it "should be 0" do
      expect("Blue Whale".index_of("")).to match(0)
    end

    it "should be 9" do
      expect("Blue Whale".index_of("", 9)).to match(9)
    end
  end #index_of
end

RSpec.describe DiffMatchPatch do
  describe "#diff_chars_to_lines" do
    subject do
      described_class.new.diff_chars_to_lines(diffs, line_array)
    end

    context "Convert chars up to lines." do
      let(:diffs)      { [["DIFF_EQUAL", "\x01\x02\x01"], ["DIFF_INSERT", "\x02\x01\x02"]] }
      let(:line_array) { ["", "alpha\n", "beta\n"] }
      it { is_expected.to match([["DIFF_EQUAL", "alpha\nbeta\nalpha\n"], ["DIFF_INSERT", "beta\nalpha\nbeta\n"]]) }
    end
  end #diff_chars_to_lines

  describe "#diff_common_prefix" do
    subject do
      described_class.new.diff_common_prefix(text1, text2)
    end

    context "for null case" do
      let(:text1) { "abc" }
      let(:text2) { "xyx" }
      it { is_expected.to match(0) }
    end

    context "for No-null case" do
      let(:text1) { "1234abcdef" }
      let(:text2) { "1234xyz" }
      it { is_expected.to match(4) }
    end

    context "for whole case" do
      let(:text1) { "1234" }
      let(:text2) { "1234xyz" }
      it { is_expected.to match(4) }
    end
  end #diff_common_prefix

  describe "#diff_common_suffix" do
    subject do
      described_class.new.diff_common_suffix(text1, text2)
    end

    context "for null case" do
      let(:text1) { "abc" }
      let(:text2) { "xyx" }
      it { is_expected.to match(0) }
    end

    context "for No-null case" do
      let(:text1) { "abcdef1234" }
      let(:text2) { "xyz1234" }
      it { is_expected.to match(4) }
    end

    context "for whole case" do
      let(:text1) { "1234" }
      let(:text2) { "xyz1234" }
      it { is_expected.to match(4) }
    end
  end #diff_common_suffix

  describe "#diff_common_overlap" do
    subject do
      described_class.new.diff_common_overlap(text1, text2)
    end

    context "for null case" do
      let(:text1) { "" }
      let(:text2) { "abcd" }
      it { is_expected.to match(0) }
    end

    context "for whole case." do
      let(:text1) { "abc" }
      let(:text2) { "abcd" }
      it { is_expected.to match(3) }
    end

    context "for no overlap case" do
      let(:text1) { "123456" }
      let(:text2) { "abcd" }
      it { is_expected.to match(0) }
    end

    context "for overlap case" do
      let(:text1) { "123456xxx" }
      let(:text2) { "xxxabcd" }
      it { is_expected.to match(3) }
    end

    # Some overly clever languages (C#) may treat ligatures as equal to their
    # component letters.  E.g. U+FB01 == 'fi'
    context "for unicode case" do
      let(:text1) { "fi" }
      let(:text2) { "\ufb01i" }
      it { is_expected.to match(0) }
    end
  end #diff_common_overlap

  describe "#diff_half_match" do
    subject do
      described_class.new.diff_half_match(text1, text2)
    end

    context "for no match case" do
      context "pattern 1" do
        let(:text1) { "1234567890" }
        let(:text2) { "abcdef" }
        it { is_expected.to match(nil) }
      end

      context "pattern 2" do
        let(:text1) { "12345" }
        let(:text2) { "23" }
        it { is_expected.to match(nil) }
      end
    end

    context "for single match case" do
      context "pattern 1" do
        let(:text1) { "1234567890" }
        let(:text2) { "a345678z" }
        it { is_expected.to match(["12", "90", "a", "z", "345678"]) }
      end

      context "pattern 2" do
        let(:text1) { "a345678z" }
        let(:text2) { "1234567890" }
        it { is_expected.to match(["a", "z", "12", "90", "345678"]) }
      end

      context "pattern 3" do
        let(:text1) { "abc56789z" }
        let(:text2) { "1234567890" }
        it { is_expected.to match(["abc", "z", "1234", "0", "56789"]) }
      end

      context "pattern 4" do
        let(:text1) { "a23456xyz" }
        let(:text2) { "1234567890" }
        it { is_expected.to match(["a", "xyz", "1", "7890", "23456"]) }
      end
    end

    context "for multiple matches case" do
      context "pattern 1" do
        let(:text1) { "121231234123451234123121" }
        let(:text2) { "a1234123451234z" }
        it { is_expected.to match(["12123", "123121", "a", "z", "1234123451234"]) }
      end

      context "pattern 1" do
        let(:text1) { "x-=-=-=-=-=-=-=-=-=-=-=-=" }
        let(:text2) { "xx-=-=-=-=-=-=-=" }
        it { is_expected.to match(["", "-=-=-=-=-=", "x", "", "x-=-=-=-=-=-=-="]) }
      end

      context "patter 3" do
        let(:text1) { "-=-=-=-=-=-=-=-=-=-=-=-=y" }
        let(:text2) { "-=-=-=-=-=-=-=yy" }
        it { is_expected.to match(["-=-=-=-=-=", "", "", "y", "-=-=-=-=-=-=-=y"]) }
      end
    end

    context "for non-optimal half match case" do
      let(:text1) { "qHilloHelloHew" }
      let(:text2) { "xHelloHeHulloy" }
      it { is_expected.to match(["qHillo", "w", "x", "Hulloy", "HelloHe"]) }
    end
  end #diff_half_match

  describe "#diff_lines_to_chars" do
    subject do
      described_class.new.diff_lines_to_chars(text1, text2)
    end

    context "for pattern 1" do
      let(:text1) { "alpha\nbeta\nalpha\n" }
      let(:text2) { "beta\nalpha\nbeta\n"  }
      it { is_expected.to match({ chars1: "\x01\x02\x01", chars2: "\x02\x01\x02", lineArray: ["", "alpha\n", "beta\n"] })}
    end

    context "pattern 2" do
      let(:text1) { "" }
      let(:text2) { "alpha\r\nbeta\r\n\r\n\r\n" }
      it { is_expected.to match({ chars1: "", chars2: "\x01\x02\x03\x03", lineArray: ["", "alpha\r\n", "beta\r\n", "\r\n"] })}
    end

    context "pattern 3" do
      let(:text1) { "a" }
      let(:text2) { "b" }
      it { is_expected.to match({ chars1: "\x01", chars2: "\x02", lineArray: ["", "a", "b"] })}
    end

    context "for more than 256 to reveal any 8-bit limitations." do
      it "pattern 1" do
        n = 300
        line_list = []
        char_list = []
        (1...(n + 1)).each do |i|
          line_list[i - 1] = "#{i}\n"
          char_list[i - 1] = i.chr("UTF-8")
        end
        expect(n).to match(line_list.size)
        lines = line_list.join("")
        chars = char_list.join("")
        expect(n).to match(chars.size)
        line_list.unshift("")
        expect(described_class.new.diff_lines_to_chars(lines, "")).to match({ chars1: chars, chars2: "", lineArray: line_list })
      end
    end
  end #diff_lines_to_chars

  describe "#diff_chars_to_lines" do
    it "pattern1" do
      diffs      = [["DIFF_EQUAL", "\x01\x02\x01"], ["DIFF_INSERT", "\x02\x01\x02"]]
      line_array = ["", "alpha\n", "beta\n"]
      described_class.new.diff_chars_to_lines(diffs, line_array)
      expect(diffs).to match([["DIFF_EQUAL", "alpha\nbeta\nalpha\n"], ["DIFF_INSERT", "beta\nalpha\nbeta\n"]])
    end

    context "for more than 256 to reveal any 8-bit limitations" do
      it "pattern 1" do
        n = 300
        line_list = []
        char_list = []
        (1...(n + 1)).each do |i|
          line_list[i - 1] = "#{i}\n"
          char_list[i - 1] = i.chr("UTF-8")
        end
        expect(n).to match(line_list.size)
        lines = line_list.join("")
        chars = char_list.join("")
        expect(n).to match(chars.size)
        line_list.unshift("")
        diffs = [["DIFF_DELETE", chars]]
        described_class.new.diff_chars_to_lines(diffs, line_list)
        expect(diffs).to match([["DIFF_DELETE", lines]])
      end
    end

    context "for more than 65536 to verify any 16-bit limitation" do
      it "pattern 1" do
        line_list = []
        (0...66000).each do |i|
          line_list[i] = "#{i}\n"
        end
        chars = line_list.join("")
        results = described_class.new.diff_lines_to_chars(chars, "")
        diffs = [["DIFF_INSERT", results[:chars1]]]
        described_class.new.diff_chars_to_lines(diffs, results[:lineArray])
        expect(chars).to match(diffs[0][1])
      end
    end
  end #diff_chars_to_lines

  describe "#diff_cleanup_merge" do
    context "for null case" do
      it "should be []" do
        diffs = []
        described_class.new.diff_cleanup_merge(diffs)
        expect([]).to match(diffs)
      end
    end

    context "for no change case" do
      it "should be [[\"DIFF_EQUAL\", \"a\"], [\"DIFF_DELETE\", \"b\"], [\"DIFF_INSERT\", \"c\"]]" do
        diffs = [["DIFF_EQUAL", "a"], ["DIFF_DELETE", "b"], ["DIFF_INSERT", "c"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_EQUAL", "a"], ["DIFF_DELETE", "b"], ["DIFF_INSERT", "c"]]).to match(diffs)
      end
    end

    context "for merge equalities" do
      it "should be [[\"DIFF_EQUAL\", \"a\"], [\"DIFF_EQUAL\", \"b\"], [\"DIFF_EQUAL\", \"c\"]]" do
        diffs = [["DIFF_EQUAL", "a"], ["DIFF_EQUAL", "b"], ["DIFF_EQUAL", "c"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_EQUAL", "abc"]]).to match(diffs)
      end
    end

    context "for merge deletions" do
      it "should be [[\"DIFF_DELETE\", \"abc\"]]" do
        diffs = [["DIFF_DELETE", "a"], ["DIFF_DELETE", "b"], ["DIFF_DELETE", "c"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_DELETE", "abc"]]).to match(diffs)
      end
    end

    context "for merge insertions" do
      it "should be [[\"DIFF_INSERT\", \"abc\"]]" do
        diffs = [["DIFF_INSERT", "a"], ["DIFF_INSERT", "b"], ["DIFF_INSERT", "c"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_INSERT", "abc"]]).to match(diffs)
      end
    end

    context "for merge interweave" do
      it "should be [[\"DIFF_DELETE\", \"ac\"], [\"DIFF_INSERT\", \"bd\"], [\"DIFF_EQUAL\", \"ef\"]]" do
        diffs = [["DIFF_DELETE", "a"], ["DIFF_INSERT", "b"], ["DIFF_DELETE", "c"], ["DIFF_INSERT", "d"], ["DIFF_EQUAL", "e"], ["DIFF_EQUAL", "f"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_DELETE", "ac"], ["DIFF_INSERT", "bd"], ["DIFF_EQUAL", "ef"]]).to match(diffs)
      end
    end

    context "for prefix and suffix detection" do
      it "should be [[\"DIFF_EQUAL\", \"a\"], [\"DIFF_DELETE\", \"d\"], [\"DIFF_INSERT\", \"b\"], [\"DIFF_EQUAL\", \"c\"]]" do
        diffs = [["DIFF_DELETE", "a"], ["DIFF_INSERT", "abc"], ["DIFF_DELETE", "dc"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_EQUAL", "a"], ["DIFF_DELETE", "d"], ["DIFF_INSERT", "b"], ["DIFF_EQUAL", "c"]]).to match(diffs)
      end
    end

    context "for prefix and suffix detection with equalities" do
      it "should be [[\"DIFF_EQUAL\", \"xa\"], [\"DIFF_DELETE\", \"d\"], [\"DIFF_INSERT\", \"b\"], [\"DIFF_EQUAL\", \"cy\"]]" do
        diffs = [["DIFF_EQUAL", 'x'], ["DIFF_DELETE", "a"], ["DIFF_INSERT", "abc"], ["DIFF_DELETE", "dc"], ["DIFF_EQUAL", "y"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_EQUAL", "xa"], ["DIFF_DELETE", "d"], ["DIFF_INSERT", "b"], ["DIFF_EQUAL", "cy"]]).to match(diffs)
      end
    end

    context "for slide edit left." do
      it "should be [[\"DIFF_EQUAL\", \"ca\"], [\"DIFF_INSERT\", \"ba\"]]" do
        diffs = [["DIFF_EQUAL", "c"], ["DIFF_INSERT", "ab"], ["DIFF_EQUAL", "a"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_EQUAL", "ca"], ["DIFF_INSERT", "ba"]]).to match(diffs)
      end
    end

    context "for slide edit right." do
      it "should be [[\"DIFF_INSERT\", \"ab\"], [\"DIFF_EQUAL\", \"ac\"]]" do
        diffs = [["DIFF_EQUAL", "a"], ["DIFF_INSERT", "ba"], ["DIFF_EQUAL", "c"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_INSERT", "ab"], ["DIFF_EQUAL", "ac"]]).to match(diffs)
      end
    end

    context "for slide edit left recursive." do
      it "should be [[\"DIFF_DELETE\", \"abc\"], [\"DIFF_EQUAL\", \"acx\"]]" do
      diffs = [["DIFF_EQUAL", "a"], ["DIFF_DELETE", "b"], ["DIFF_EQUAL", "c"], ["DIFF_DELETE", "ac"], ["DIFF_EQUAL", "x"]]
      described_class.new.diff_cleanup_merge(diffs)
      expect([["DIFF_DELETE", "abc"], ["DIFF_EQUAL", "acx"]]).to match(diffs)
        end
    end

    context "for slide edit right recursive." do
      it "should be [[\"DIFF_EQUAL\", \"xca\"], [\"DIFF_DELETE\", \"cba\"]]" do
        diffs = [["DIFF_EQUAL", "x"], ["DIFF_DELETE", "ca"], ["DIFF_EQUAL", "c"], ["DIFF_DELETE", "b"], ["DIFF_EQUAL", "a"]]
        described_class.new.diff_cleanup_merge(diffs)
        expect([["DIFF_EQUAL", "xca"], ["DIFF_DELETE", "cba"]]).to match(diffs)
      end
    end
  end #diff_cleanup_merge

  describe "#diff_cleanup_semantic_lossless" do
    context "for null case" do
      it "should be []" do
        diffs = []
        described_class.new.diff_cleanup_semantic_lossless(diffs)
        expect([]).to match(diffs)
      end
    end

    context "for blank lines" do
      it "should be [[\"DIFF_EQUAL\", \"AAA\r\n\r\n\"], [\"DIFF_INSERT\", \"BBB\r\nDDD\r\n\r\n\"], [\"DIFF_EQUAL\", \"BBB\r\nEEE\"]]" do
        diffs = [["DIFF_EQUAL", "AAA\r\n\r\nBBB"], ["DIFF_INSERT", "\r\nDDD\r\n\r\nBBB"], ["DIFF_EQUAL", "\r\nEEE"]]
        described_class.new.diff_cleanup_semantic_lossless(diffs)
        expect([["DIFF_EQUAL", "AAA\r\n\r\n"], ["DIFF_INSERT", "BBB\r\nDDD\r\n\r\n"], ["DIFF_EQUAL", "BBB\r\nEEE"]]).to match(diffs)
      end
    end

    context "for line boundaries" do
      it "should be [[\"DIFF_EQUAL\", \"AAA\r\n\"], [\"DIFF_INSERT\", \"BBB DDD\r\n\"], [\"DIFF_EQUAL\", \"BBB EEE\"]]" do
        diffs = [["DIFF_EQUAL", "AAA\r\nBBB"], ["DIFF_INSERT", " DDD\r\nBBB"], ["DIFF_EQUAL", " EEE"]]
        described_class.new.diff_cleanup_semantic_lossless(diffs)
        expect([["DIFF_EQUAL", "AAA\r\n"], ["DIFF_INSERT", "BBB DDD\r\n"], ["DIFF_EQUAL", "BBB EEE"]]).to match(diffs)
      end
    end

    context "for word boundaries" do
      it "should be [[\"DIFF_EQUAL\", \"The \"], [\"DIFF_INSERT\", \"cow and the \"], [\"DIFF_EQUAL\", \"cat.\"]]" do
        diffs = [["DIFF_EQUAL", "The c"], ["DIFF_INSERT", "ow and the c"], ["DIFF_EQUAL", "at."]]
        described_class.new.diff_cleanup_semantic_lossless(diffs)
        expect([["DIFF_EQUAL", "The "], ["DIFF_INSERT", "cow and the "], ["DIFF_EQUAL", "cat."]]).to match(diffs)
      end
    end

    context "for hitting the start" do
      it "should be [[\"DIFF_DELETE\", \"a\"], [\"DIFF_EQUAL\", \"aax\"]]" do
        diffs = [["DIFF_EQUAL", "a"], ["DIFF_DELETE", "a"], ["DIFF_EQUAL", "ax"]]
        described_class.new.diff_cleanup_semantic_lossless(diffs)
        expect([["DIFF_DELETE", "a"], ["DIFF_EQUAL", "aax"]]).to match(diffs)
      end
    end

    context "for hitting the end" do
      it "should be [[\"DIFF_EQUAL\", \"xaa\"], [\"DIFF_DELETE\", \"a\"]]" do
        diffs = [["DIFF_EQUAL", "xa"], ["DIFF_DELETE", "a"], ["DIFF_EQUAL", "a"]]
        described_class.new.diff_cleanup_semantic_lossless(diffs)
        expect([["DIFF_EQUAL", "xaa"], ["DIFF_DELETE", "a"]]).to match(diffs)
      end
    end

    context "Sentence boundaries" do
      it "should be [[\"DIFF_EQUAL\", \"The xxx.\"], [\"DIFF_INSERT\", \" The zzz.\"], [\"DIFF_EQUAL\", \" The yyy.\"]]" do
        diffs = [["DIFF_EQUAL", "The xxx. The "], ["DIFF_INSERT", "zzz. The "], ["DIFF_EQUAL", "yyy."]]
        described_class.new.diff_cleanup_semantic_lossless(diffs)
        expect([["DIFF_EQUAL", "The xxx."], ["DIFF_INSERT", " The zzz."], ["DIFF_EQUAL", " The yyy."]]).to match(diffs)
      end
    end
  end #diff_cleanup_semantic_lossless

  describe "#diff_bisect" do
    subject do
      described_class.new.diff_bisect(text1, text2, deadline)
    end

    context "for normal" do
      let(:text1)    { "cat" }
      let(:text2)    { "map" }
      let(:deadline) { 1.7976931348623157e+308 }

      it { is_expected.to match([["DIFF_DELETE", "c"], ["DIFF_INSERT", "m"], ["DIFF_EQUAL", "a"], ["DIFF_DELETE", "t"], ["DIFF_INSERT", "p"]]) }
    end

    context "for timeout" do
      let(:text1)    { "cat" }
      let(:text2)    { "map" }
      let(:deadline) { 0 }

      it { is_expected.to match([["DIFF_DELETE", "cat"], ["DIFF_INSERT", "map"]])}
    end
  end

  describe "#diff_main" do
    it "Null case." do
      expect(described_class.new.diff_main("", "", false)).to match([])
    end

    it "Equality" do
      expect(described_class.new.diff_main("abc", "abc", false)).to match([["DIFF_EQUAL", "abc"]])
    end

    it "Simple insertion" do
      expect(described_class.new.diff_main("abc", "ab123c", false)).to match([["DIFF_EQUAL", "ab"], ["DIFF_INSERT", "123"], ["DIFF_EQUAL", "c"]])
    end

    it "Simple deletion." do
      expect(described_class.new.diff_main("a123bc", "abc", false)).to match([["DIFF_EQUAL", "a"], ["DIFF_DELETE", "123"], ["DIFF_EQUAL", "bc"]])
    end

    it "Two insertions." do
      expect(described_class.new.diff_main("abc", "a123b456c", false)).to match([["DIFF_EQUAL", "a"], ["DIFF_INSERT", "123"], ["DIFF_EQUAL", "b"], ["DIFF_INSERT", "456"], ["DIFF_EQUAL", "c"]])
    end

    it "Two deletions." do
      expect(described_class.new.diff_main("a123b456c", "abc", false)).to match([["DIFF_EQUAL", 'a'], ["DIFF_DELETE", "123"], ["DIFF_EQUAL", "b"], ["DIFF_DELETE", "456"], ["DIFF_EQUAL", "c"]])
    end

    context "when the timeout is switched off" do
      # Perform a real diff.
      # Switch off the timeout.
      dmp = described_class.new
      dmp.diff_timeout = 0

      it "simple case 1" do
        expect(dmp.diff_main("a", "b", false)).to match([["DIFF_DELETE", "a"], ["DIFF_INSERT", "b"]])
      end

      it "simple case 2" do
        expect(dmp.diff_main("Apples are a fruit.", "Bananas are also fruit.", false)).to match([["DIFF_DELETE", "Apple"], ["DIFF_INSERT", "Banana"], ["DIFF_EQUAL", "s are a"], ["DIFF_INSERT", "lso"], ["DIFF_EQUAL", " fruit."]])
      end

      it "simple case 3" do
        expect(dmp.diff_main("ax\t", "\u0680x\0", false)).to match([["DIFF_DELETE", "a"], ["DIFF_INSERT", "\u0680"], ["DIFF_EQUAL", "x"], ["DIFF_DELETE", "\t"], ["DIFF_INSERT", "\0"]])
      end

      it "overlaps case 1" do
        expect(dmp.diff_main("1ayb2", "abxab", false)).to match([["DIFF_DELETE", "1"], ["DIFF_EQUAL", "a"], ["DIFF_DELETE", "y"], ["DIFF_EQUAL", "b"], ["DIFF_DELETE", "2"], ["DIFF_INSERT", "xab"]])
      end

      it "overlaps case 2" do
        expect(dmp.diff_main("abcy", "xaxcxabc", false)).to match([["DIFF_INSERT", "xaxcx"], ["DIFF_EQUAL", "abc"], ["DIFF_DELETE", "y"]])
      end

      it "overlaps case 3" do
        expect(dmp.diff_main("ABCDa=bcd=efghijklmnopqrsEFGHIJKLMNOefg", "a-bcd-efghijklmnopqrs", false)).to match([["DIFF_DELETE", "ABCD"], ["DIFF_EQUAL", "a"], ["DIFF_DELETE", "="], ["DIFF_INSERT", "-"], ["DIFF_EQUAL", "bcd"], ["DIFF_DELETE", "="], ["DIFF_INSERT", "-"], ["DIFF_EQUAL", "efghijklmnopqrs"], ["DIFF_DELETE", "EFGHIJKLMNOefg"]])
      end

      it "large equality case" do
        expect(dmp.diff_main("a [[Pennsylvania]] and [[New", " and [[Pennsylvania]]", false)).to match([["DIFF_INSERT", " "], ["DIFF_EQUAL", "a"], ["DIFF_INSERT", "nd"], ["DIFF_EQUAL", " [[Pennsylvania]]"], ["DIFF_DELETE", " and [[New"]])
      end
    end

    context "when the timeout is switched on" do
      context "a" do
        # Perform a real diff.
        # Switch off the timeout.
        dmp = described_class.new
        dmp.diff_timeout = 0.1  # 100ms

        it "" do
          a = "`Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\nAnd the mome raths outgrabe.\n"
          b = "I am the very model of a modern major general,\nI've information vegetable, animal, and mineral,\nI know the kings of England, and I quote the fights historical,\nFrom Marathon to Waterloo, in order categorical.\n"
          # Increase the text lengths by 1024 times to ensure a timeout.
          (0...10).each do |_|
            a += a
            b += b
          end
          start_time = Time.now.strftime('%s%L').to_i
          dmp.diff_main(a, b)
          end_time   = Time.now.strftime('%s%L').to_i
          # Test that we took at least the timeout period.
          expect(dmp.diff_timeout <= end_time - start_time).to match(true)
          # Test that we didn't take forever (be forgiving).
          # Theoretically this test could fail very occasionally if the -
          # OS task swaps or locks up for a second at the wrong moment.

          # expect(dmp.diff_timeout * 1000 * 2 > end_time - start_time).to match(true)
        end
      end

      context "b" do
        dmp = described_class.new
        dmp.diff_timeout = 0

        # Test the linemode speedup.
        # Must be long to pass the 100 char cutoff.
        it "simple line-mode case 1" do
          a = "1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n"
          b = "abcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\n"
          expect(dmp.diff_main(a, b, false)).to match(dmp.diff_main(a, b, true))
        end

        it "simple line-mode case 2" do
          a = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
          b = "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"
          expect(dmp.diff_main(a, b, false)).to match(dmp.diff_main(a, b, true))
        end

        it "overlap line-mode case 1" do
          a = "1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n"
          b = "abcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n"
          texts_line_mode = diff_rebuild_texts(dmp.diff_main(a, b, true))
          texts_text_mode = diff_rebuild_texts(dmp.diff_main(a, b, false))
          expect(texts_text_mode).to match(texts_line_mode)
        end
      end
    end
  end #diff_main

  describe "#diff_pretty_html" do
    subject do
      described_class.new.diff_pretty_html(diffs)
    end

    let(:diffs) { [["DIFF_EQUAL", 'a\n'], ["DIFF_DELETE", '<B>b</B>'], ["DIFF_INSERT", 'c&d']] }
    it { is_expected.to match("<span>a&para;<br></span><del>&lt;B&gt;b&lt;/B&gt;</del><ins>c&amp;d</ins>") }
  end #diff_pretty_html

  private

  def diff_rebuild_texts(diffs)
    # Construct the two texts which made up the diff originally.
    text1 = ""
    text2 = ""
    (0...diffs.size).each do |x|
      if diffs[x][0] != "DIFF_INSERT"
        text1 += diffs[x][1]
      end

      if diffs[x][0] != "DIFF_DELETE"
        text2 += diffs[x][1]
      end
    end
    return [text1, text2]
  end

end
