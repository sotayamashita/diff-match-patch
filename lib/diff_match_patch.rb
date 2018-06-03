class String
  # @return The part of the string between the start and end indexes, or to the end of the string.
  def substring(index_start, index_end = nil)
    if index_end
      # If indexStart is equal to indexEnd, substring() returns an empty string.
      return "" if index_start == index_end
      # If indexStart is greater than indexEnd, then the effect of substring() is as if the two arguments were swapped.
      return self[(index_end)...(index_start)] if index_start > index_end

      self[(index_start)...(index_end)]
    else
      # If indexEnd is omitted, substring() extracts characters to the end of the string.
      self[(index_start)...(self.size)]
    end
  end

  # @return The first index at which a given element can be found in the array, or -1 if it is not present.
  def index_of(search_element, from_index = nil)
    (from_index ? self.index(search_element, from_index) : self.index(search_element)) || -1
  end
end

class Array
  def splice(start, len, *replace)
    ret = self[start, len]
    self[start, len] = replace
    ret
  end
end

class DiffMatchPatch
  attr_accessor :diff_timeout

  def initialize
    # Number of seconds to map a diff before giving up (0 for infinity).
    @diff_timeout = 1.0
  end

  def diff_main(text1, text2, opt_checklines = false, opt_deadline = nil)
    # Set a deadline by which time the diff must be complete.
    if opt_deadline.nil?
      if diff_timeout <= 0
        opt_deadline = max_number
      else
        opt_deadline = get_time + diff_timeout * 1000
      end
    end
    deadline = opt_deadline

    # Check for null inputs.
    if text1.nil? || text2.nil?
      raise StandardError.new("Nil input. (diff_main)")
    end

    # Check for equality (speedup).
    if text1 == text2
      # Handle empty string as nil
      text1 = text1.to_s.empty? ? nil : text1
      if text1
        return [["DIFF_EQUAL", text1]]
      end
      return []
    end

    if opt_checklines.nil?
      opt_checklines = true
    end
    checklines = opt_checklines

    # Trim off common prefix (speedup)
    common_length = diff_common_prefix(text1, text2)
    common_prefix = text1.substring(0, common_length)
    # Handle empty string as nil
    common_prefix = common_prefix.to_s.empty? ? nil : common_prefix
    text1 = text1.substring(common_length)
    text2 = text2.substring(common_length)

    # Trim off common suffix (speedup).
    common_length = diff_common_suffix(text1, text2)
    common_suffix = text1.substring(text1.size - common_length)
    # Handle empty string as nil
    common_suffix = common_suffix.to_s.empty? ? nil : common_suffix
    text1 = text1.substring(0, (text1.size - common_length))
    text2 = text2.substring(0, (text2.size - common_length))

    # Compute the diff on the middle block.
    diffs = diff_compute(text1, text2, checklines, deadline)

    if common_prefix
      diffs.unshift(["DIFF_EQUAL", common_prefix])
    end

    if common_suffix
      diffs.push(["DIFF_EQUAL", common_suffix])
    end

    diff_cleanup_merge(diffs)
    diffs
  end

  def diff_compute(text1, text2, checklines, deadline)
    # Handle empty string as nil
    text1 = text1.to_s.empty? ? nil : text1
    unless text1
      # Just add some text (speedup).
      return [["DIFF_INSERT", text2]]
    end

    # Handle empty string as nil
    text2 = text2.to_s.empty? ? nil : text2
    unless text2
      # Just delete some text (speedup).
      return [["DIFF_DELETE", text1]]
    end

    long_text  = text1.size > text2.size ? text1 : text2
    short_text = text1.size > text2.size ? text2 : text1
    i = long_text.index_of(short_text)
    if i != -1
      # Shorter text is inside the longer text (speedup).
      diffs = [["DIFF_INSERT", long_text.substring(0, i)], ["DIFF_EQUAL", short_text], ["DIFF_INSERT", long_text.substring(i + short_text.size)]]
      # Swap insertions for deletions if diff is reversed.
      if text1.size > text2.size
        diffs[0][0] = diffs[2][0] = "DIFF_DELETE"
      end
      return diffs
    end

    if short_text.size == 1
      # Single character string.
      # After the previous speedup, the character can't be an equality.
      return [["DIFF_DELETE", text1], ["DIFF_INSERT", text2]];
    end

    # Check to see if the problem can be split in two.
    hm = diff_half_match(text1, text2)
    if hm
      # A half-match was found, sort out the return data.
      text1_a    = hm[0]
      text1_b    = hm[1]
      text2_a    = hm[2]
      text2_b    = hm[3]
      mid_common = hm[4]

      # Send both pairs off for separate processing.
      diffs_a = diff_main(text1_a, text2_a, checklines, deadline)
      diffs_b = diff_main(text1_b, text2_b, checklines, deadline)
      # Merge the results.
      return diffs_a + [["DIFF_EQUAL", mid_common]] + diffs_b
    end

    if checklines && text1.size > 100 && text2.size > 100
      return diff_line_mode(text1, text2, deadline)
    end

    diff_bisect(text1, text2, deadline)
  end

  def diff_half_match(text1, text2)
    if diff_timeout <= 0
      # Don't risk returning a non-optimal diff if we have unlimited time.
      return nil
    end

    long_text  = text1.size > text2.size ? text1 : text2
    short_text = text1.size > text2.size ? text2 : text1
    if long_text.size < 4 || short_text.size * 2 < long_text.size
      return nil # Pintless.
    end

    # First check if the second quarter is the seed for a half-match.
    hm1 = diff_half_match_i(long_text, short_text, (long_text.size / 4).ceil)
    # Check again based on the third quarter.
    hm2 = diff_half_match_i(long_text, short_text, (long_text.size / 2).ceil)

    if !hm1 && !hm2
      return nil
    elsif !hm2
      hm = hm1
    elsif !hm1
      hm = hm2
    else
      # Both matched.  Select the longest.
      hm = hm1[4].size > hm2[4].size ? hm1 : hm2
    end

    # A half-match was found, sort out the return data.
    if text1.size > text2.size
      text1_a = hm[0]
      text1_b = hm[1]
      text2_a = hm[2]
      text2_b = hm[3]
    else
      text2_a = hm[0]
      text2_b = hm[1]
      text1_a = hm[2]
      text1_b = hm[3]
    end
    mid_common = hm[4]

    [text1_a, text1_b, text2_a, text2_b, mid_common]
  end

  def diff_half_match_i(long_text, short_text, i)
    # Start with a 1/4 length substring at position i as a seed.
    seed = long_text.substring(i, i + (long_text.size / 4).floor)
    j = -1
    best_common = ""
    while (j = short_text.index_of(seed, j + 1)) != -1
      prefix_length = diff_common_prefix(long_text.substring(i), short_text.substring(j))
      suffix_length = diff_common_suffix(long_text.substring(0, i), short_text.substring(0, j))
      if best_common.size < suffix_length + prefix_length
        best_common = short_text.substring((j - suffix_length), j) + short_text.substring(j, (j + prefix_length))
        best_long_text_a  = long_text.substring(0, i - suffix_length)
        best_long_text_b  = long_text.substring(i + prefix_length)
        best_short_text_a = short_text.substring(0, j - suffix_length)
        best_short_text_b = short_text.substring(j + prefix_length)
      end
    end
    if best_common.size * 2 >= long_text.size
      return [best_long_text_a, best_long_text_b, best_short_text_a, best_short_text_b, best_common]
    else
      return nil
    end
  end

  def diff_line_mode(text1, text2, deadline)
    # Scan the text on a line-by-line basis first.
    a = diff_lines_to_chars(text1, text2)
    text1 = a[:chars1]
    text2 = a[:chars2]
    line_array = a[:lineArray]

    diffs = diff_main(text1, text2, false, deadline)

    # Convert the diff back to original text.
    diff_chars_to_lines(diffs, line_array)
    # Eliminate freak matches (e.g. blank lines)
    diff_cleanup_semantic(diffs)

    # Rediff any replacement blocks, this time character-by-character.
    # Add a dummy entry at the end.
    diffs.push(["DIFF_EQUAL", ""])
    pointer = 0
    count_delete = 0
    count_insert = 0
    text_delete = ""
    text_insert = ""
    while pointer < diffs.size
      case diffs[pointer][0]
      when "DIFF_INSERT"
        count_insert += 1
        text_insert += diffs[pointer][1]
      when "DIFF_DELETE"
        count_delete += 1
        text_delete += diffs[pointer][1]
      when "DIFF_EQUAL"
        # Upon reaching an equality, check for prior redundancies.
        if count_delete >= 1 && count_insert >= 1
          diffs.splice(pointer - count_delete - count_insert, count_delete + count_insert)
          pointer = pointer - count_delete - count_insert
          a = diff_main(text_delete, text_insert, false, deadline)
          (a.size - 1).downto(0) do |j|
            diffs.splice(pointer, 0, a[j])
          end
          pointer = pointer + a.size
        end
        count_insert = 0
        count_delete = 0
        text_delete = ""
        text_insert = ""
      end
      pointer += 1
    end
    # Remove the dummy entry at the end.
    diffs.pop
    diffs
  end

  def diff_lines_to_chars(text1, text2)
    line_array = []
    line_hash  = {}

    # "\x00" is a valid character, but various debuggers don't like it.
    # So we'll insert a junk entry to avoid generating a null character.
    line_array[0] = ""

    chars1 = diff_lines_to_chars_munge(text1, line_array, line_hash, 40000)
    chars2 = diff_lines_to_chars_munge(text2, line_array, line_hash, 65535)

    { chars1: chars1, chars2: chars2, lineArray: line_array }
  end

  def diff_lines_to_chars_munge(text, line_array, line_hash, max_lines)
    chars = ""
    # Walk the text, pulling out a substring for each line.
    # text.split('\n') would would temporarily double our memory footprint.
    # Modifying text would create many large strings to garbage collect.
    line_start = 0
    line_end  = -1
    # Keeping our own length variable is faster than looking it up.
    line_array_length = line_array.size
    while line_end < text.size - 1
      line_end = text.index_of("\n", line_start)
      if line_end == -1
        line_end = text.size - 1
      end
      line = text.substring(line_start, line_end + 1)

      if line_hash[line]
        chars += line_hash[line].chr("UTF-8")
      else
        if line_array_length == max_lines
          # Bail out at 65535 because
          # String.fromCharCode(65536) == String.fromCharCode(0)
          line = text.substring(line_start)
          line_end = text.size
        end
        chars += line_array_length.chr("UTF-8")
        line_hash[line] = line_array_length
        line_array[line_array_length] = line
        line_array_length += 1
      end
      line_start = line_end + 1
    end

    chars
  end

  def diff_cleanup_semantic(diffs)
    changes    = false
    equalities = []
    equalities_length = 0
    last_equality = nil
    # Always equal to diffs[equalities[equalitiesLength - 1]][1]
    pointer = 0
    # Number of characters that changed prior to the equality.
    length_insertions1 = 0
    length_deletions1  = 0
    # Number of characters that changed after the equality.
    length_insertions2 = 0
    length_deletions2  = 0
    while pointer < diffs.size
      if diffs[pointer][0] == "DIFF_EQUAL" # Equality found.
        equalities[equalities_length] = pointer
        equalities_length += 1

        length_insertions1 = length_insertions2
        length_deletions1  = length_deletions2

        length_insertions2 = 0
        length_deletions2  = 0
        last_equality      = diffs[pointer][1]
      else # An insertion or deletion.
        if diffs[pointer][0] == "DIFF_INSERT"
          length_insertions2 += diffs[pointer][1].size
        else
          length_deletions2  += diffs[pointer][1].size
        end
        # Eliminate an equality that is smaller or equal to the edits on both
        # sides of it.
        if last_equality && (last_equality.size <= [length_insertions1, length_deletions1].max) && (last_equality.size <= [length_insertions2, length_deletions2].max)
          # Duplicate record.
          diffs.splice(equalities[equalities_length - 1], 0, ["DIFF_DELETE", last_equality])
          # Change second copy to insert.
          diffs[equalities[equalities_length - 1] + 1][0] = "DIFF_INSERT"
          # Throw away the equality we just deleted.
          equalities_length -= 1
          # Throw away the previous equality (it needs to be reevaluated).
          equalities_length -= 1
          pointer = equalities_length > 0 ? equalities[equalities_length - 1] : -1
          # Reset the counters.
          length_insertions1 = 0
          length_deletions1  = 0
          length_insertions2 = 0
          length_deletions2  = 0
          last_equality      = nil
          changes            = true
        end
      end
      pointer += 1
    end

    # Normalize the diff.
    if changes
      diff_cleanup_merge(diffs)
    end
    diff_cleanup_semantic_lossless(diffs)

    # Find any overlaps between deletions and insertions.
    # e.g: <del>abcxxx</del><ins>xxxdef</ins>
    #   -> <del>abc</del>xxx<ins>def</ins>
    # e.g: <del>xxxabc</del><ins>defxxx</ins>
    #   -> <ins>def</ins>xxx<del>abc</del>
    # Only extract an overlap if it is as big as the edit ahead or behind it.
    pointer = 1
    while pointer < diffs.size
      if diffs[pointer - 1][0] == "DIFF_DELETE" && diffs[pointer][0] == "DIFF_INSERT"
        deletion  = diffs[pointer - 1][1]
        insertion = diffs[pointer][1]
        overlap_length1 = diff_common_overlap(deletion, insertion)
        overlap_length2 = diff_common_overlap(insertion, deletion)
        if overlap_length1 >= overlap_length2
          if overlap_length1 >= (deletion.size / 2) || overlap_length1 >= (insertion.size / 2)
            # Overlap found.  Insert an equality and trim the surrounding edits.
            diffs.splice(pointer, 0, ["DIFF_EQUAL", insertion.substring(0, overlap_length1)])
            diffs[pointer - 1][1] = deletion.substring(0, deletion.size - overlap_length1)
            diffs[pointer + 1][1] = insertion.substring(overlap_length1)
            pointer += 1
          end
        else
          if overlap_length2 >= (deletion.size / 2.to_f) || overlap_length2 >= (insertion.size / 2.to_f)
            # Reverse overlap found.
            # Insert an equality and swap and trim the surrounding edits.
            diffs.splice(pointer, 0,["DIFF_EQUAL", deletion.substring(0, overlap_length2)])
            diffs[pointer - 1][0] = "DIFF_INSERT"
            diffs[pointer - 1][1] = insertion.substring(0, insertion.size - overlap_length2)
            diffs[pointer + 1][0] = "DIFF_DELETE"
            diffs[pointer + 1][1] = deletion.substring(overlap_length2)
            pointer += 1
          end
        end
        pointer += 1
      end
      pointer += 1
    end
  end

  def diff_cleanup_merge(diffs)
    diffs.push(["DIFF_EQUAL", ""]) #  Add a dummy entry at the end.
    pointer      = 0
    count_delete = 0
    count_insert = 0
    text_delete  = ""
    text_insert  = ""
    while pointer < diffs.size
      case diffs[pointer][0]
      when "DIFF_INSERT"
        count_insert += 1
        text_insert  += diffs[pointer][1]
        pointer      += 1
      when "DIFF_DELETE"
        count_delete += 1
        text_delete  += diffs[pointer][1]
        pointer      += 1
      when "DIFF_EQUAL"
        # Upon reaching an equality, check for prior redundancies.
        if count_delete + count_insert > 1
          if count_delete != 0 && count_insert != 0
            # Factor out any common prefixes.
            common_length = diff_common_prefix(text_insert, text_delete)
            if common_length != 0
              if (pointer - count_delete - count_insert) > 0 && diffs[pointer - count_delete - count_insert - 1][0] == "DIFF_EQUAL"
                diffs[pointer - count_delete - count_insert - 1][1] += text_insert.substring(0, common_length);
              else
                diffs.splice(0, 0, ["DIFF_EQUAL", text_insert.substring(0, common_length)])
                pointer += 1
              end
              text_insert = text_insert.substring(common_length)
              text_delete = text_delete.substring(common_length)
            end
            # Factor out any common suffixes.
            common_length = diff_common_suffix(text_insert, text_delete)
            if common_length != 0
              diffs[pointer][1] = text_insert.substring(text_insert.size - common_length) + diffs[pointer][1]
              text_insert = text_insert.substring(0, text_insert.size - common_length)
              text_delete = text_delete.substring(0, text_delete.size - common_length)
            end
          end
          # Delete the offending records and add the merged ones.
          if count_delete == 0
            diffs.splice(pointer - count_insert, count_delete + count_insert, ["DIFF_INSERT", text_insert])
          elsif count_insert == 0
            diffs.splice(pointer - count_delete, count_delete + count_insert, ["DIFF_DELETE", text_delete])
          else
            diffs.splice(pointer - count_delete - count_insert, count_delete + count_insert, ["DIFF_DELETE", text_delete], ["DIFF_INSERT", text_insert])
          end
          pointer = pointer - count_delete - count_insert + (count_delete ? 1 : 0) + (count_insert ? 1 : 0) + 1
        elsif pointer != 0 && diffs[pointer - 1][0] == "DIFF_EQUAL"
          # Merge this equality with the previous one.
          diffs[pointer - 1][1] += diffs[pointer][1]
          diffs.splice(pointer, 1)
        else
          pointer += 1
        end
        count_insert = 0
        count_delete = 0
        text_delete = ""
        text_insert = ""
      end
    end
    if diffs[diffs.size - 1][1] == ""
      diffs.pop # Remove the dummy entry at the end.
    end

    # Second pass: look for single edits surrounded on both sides by equalities
    # which can be shifted sideways to eliminate an equality.
    # e.g: A<ins>BA</ins>C -> <ins>AB</ins>AC
    changes = false
    pointer = 1
    # Intentionally ignore the first and last element (don't need checking).
    while pointer < diffs.size - 1
      if diffs[pointer - 1][0] == "DIFF_EQUAL" && diffs[pointer + 1][0] == "DIFF_EQUAL"
        # This is a single edit surrounded by equalities.
        if diffs[pointer][1].substring(diffs[pointer][1].size - diffs[pointer - 1][1].size) == diffs[pointer - 1][1]
          # Shift the edit over the previous equality.
          diffs[pointer][1] = diffs[pointer - 1][1] + diffs[pointer][1].substring(0, diffs[pointer][1].size - diffs[pointer - 1][1].size)
          diffs[pointer + 1][1] = diffs[pointer - 1][1] + diffs[pointer + 1][1]
          diffs.splice(pointer - 1, 1)
          changes = true
        elsif diffs[pointer][1].substring(0, diffs[pointer + 1][1].size) == diffs[pointer + 1][1]
          # Shift the edit over the next equality.
          diffs[pointer - 1][1] += diffs[pointer + 1][1]
          diffs[pointer][1] = diffs[pointer][1].substring(diffs[pointer + 1][1].size) + diffs[pointer + 1][1]
          diffs.splice(pointer + 1, 1)
          changes = true
        end
      end
      pointer += 1
    end
    # If shifts were made, the diff needs reordering and another shift sweep.
    if changes
      diff_cleanup_merge(diffs)
    end
  end

  def diff_cleanup_semantic_lossless(diffs)
    pointer = 1
    # Intentionally ignore the first and last element (don't need checking).
    while pointer < diffs.size - 1
      if diffs[pointer - 1][0] == "DIFF_EQUAL" && diffs[pointer + 1][0] == "DIFF_EQUAL"
        # This is a single edit surrounded by equalities.
        equality1 = diffs[pointer - 1][1]
        edit      = diffs[pointer][1]
        equality2 = diffs[pointer + 1][1]

        # First, shift the edit as far left as possible.
        common_offset = diff_common_suffix(equality1, edit)
        if common_offset
          common_string = edit.substring(edit.length - common_offset)
          equality1    = equality1.substring(0, equality1.length - common_offset)
          edit         = common_string + edit.substring(0, edit.length - common_offset)
          equality2    = common_string + equality2
        end

        # Second, step character by character right, looking for the best fit.
        best_equality1  = equality1
        best_edit       = edit
        best_equality2  = equality2
        best_score      = diff_cleanup_semantic_score(equality1, edit) + diff_cleanup_semantic_score(edit, equality2)

        while edit[0] == equality2[0]
          equality1 += edit[0]
          edit       = edit.substring(1) + equality2[0]
          equality2  = equality2.substring(1)
          score = diff_cleanup_semantic_score(equality1, edit) + diff_cleanup_semantic_score(edit, equality2)
          # The >= encourages trailing rather than leading whitespace on edits.
          if score >= best_score
            best_score     = score
            best_equality1 = equality1
            best_edit      = edit
            best_equality2 = equality2
          end
        end

        if diffs[pointer - 1][1] != best_equality1
          # We have an improvement, save it back to the diff.
          # Handle empty string as nil
          best_equality1 = best_equality1.to_s.empty? ? nil : best_equality1
          if best_equality1
            diffs[pointer - 1][1] = best_equality1
          else
            diffs.splice(pointer - 1, 1)
            pointer -= 1
          end
          diffs[pointer][1] = best_edit
          # Handle empty string as nil
          best_equality2 = best_equality2.to_s.empty? ? nil : best_equality2
          if best_equality2
            diffs[pointer + 1][1] = best_equality2
          else
            diffs.splice(pointer + 1, 1)
            pointer -= 1
          end
        end
      end
      pointer += 1
    end
  end

  def diff_cleanup_semantic_score(one, two)
    # Handle empty string as nil
    one = one.to_s.empty? ? nil : one
    two = two.to_s.empty? ? nil : two
    if !one || !two
     #  Edges are the best.
     return 6
    end

    # Each port of this function behaves slightly differently due to
    # subtle differences in each language's definition of things like
    # 'whitespace'.  Since this function's purpose is largely cosmetic,
    # the choice has been made to use each language's native features
    # rather than force total conformity.
    char1 = one[(one.size - 1)]
    char2 = two[0]
    non_alpha_numeric1 = char1 =~ /[^a-zA-Z0-9]/
    non_alpha_numeric2 = char2 =~ /[^a-zA-Z0-9]/
    whitespace1  = non_alpha_numeric1 && char1 =~ /\s/
    whitespace2  = non_alpha_numeric2 && char2 =~ /\s/
    line_break1  = whitespace1 && char1 =~ /[\r\n]/
    line_break2  = whitespace2 && char2 =~ /[\r\n]/
    blank_line1  = line_break1 && one =~ /\n\r?\n$/
    blank_line2  = line_break2 && two =~ /^\r?\n\r?\n/

    if blank_line1 || blank_line2
      # Five points for blank lines.
      return 5
    elsif line_break1 || line_break2
      # Four points for line breaks.
      return 4
    elsif non_alpha_numeric1 && !whitespace1 && whitespace2
      # Three points for end of sentences.
      return 3
    elsif whitespace1 || whitespace2
      # Two points for whitespace.
      return 2
    elsif non_alpha_numeric1 || non_alpha_numeric2
      # One point for non-alphanumeric.
      return 1
    end

    0
  end

  def diff_chars_to_lines(diffs, line_array)
    diffs.each do |diff|
      chars = diff[1]
      text  = []
      chars.each_char do |char|
        text.push(line_array[char.ord])
      end
      diff[1] = text.join("")
    end
  end

  def diff_common_prefix(text1, text2)
    # Quick check for common null cases.
    if !text1 || !text2 || text1[0] != text2[0]
      return 0
    end

    # Binary search
    pointer_min   = 0
    pointer_max   = [text1.size, text2.size].min
    pointer_mid   = pointer_max
    pointer_start = 0

    while pointer_min < pointer_mid
      if text1.substring(pointer_start, pointer_mid) == text2.substring(pointer_start, pointer_mid)
        pointer_min   = pointer_mid
        pointer_start = pointer_min
      else
        pointer_max = pointer_mid
      end
      pointer_mid = ((pointer_max - pointer_min) / 2.to_f + pointer_min).floor
    end

    pointer_mid
  end

  def diff_common_suffix(text1, text2)
    # Quick check for common null cases
    if !text1 || !text2 || text1[(text1.size - 1)] != text2[(text2.size - 1)]
      return 0
    end

    # Binary search.
    pointer_min = 0
    pointer_max = [text1.size, text2.size].min
    pointer_mid = pointer_max
    pointer_end = 0
    while pointer_min < pointer_mid
      if text1.substring((text1.size - pointer_mid), (text1.size - pointer_end)) == text2.substring((text2.size - pointer_mid), (text2.size - pointer_end))
        pointer_min = pointer_mid
        pointer_end = pointer_min
      else
        pointer_max = pointer_mid
      end
      pointer_mid = ((pointer_max - pointer_min) / 2 + pointer_min).floor
    end

    pointer_mid
  end

  def diff_bisect(text1, text2, deadline)
    # Cache the text lengths to prevent multiple calls.
    text1_length = text1.size
    text2_length = text2.size
    max_d = ((text1_length + text2_length) / 2.to_f).ceil
    v_offset = max_d
    v_length = 2 * max_d
    v1 = Array.new(v_length)
    v2 = Array.new(v_length)
    # Setting all elements to -1 is faster in Chrome & Firefox than mixing
    # integers and undefined.
    (0...v_length).each do |x|
      v1[x] = -1
      v2[x] = -1
    end
    v1[v_offset + 1] = 0
    v2[v_offset + 1] = 0
    delta = text1_length - text2_length
    # If the total number of characters is odd, then the front path will collide
    # with the reverse path.
    front = (delta % 2 != 0)
    # Offsets for start and end of k loop.
    # Prevents mapping of space beyond the grid.
    k1start = 0
    k1end   = 0
    k2start = 0
    k2end   = 0

    (0...max_d).each do |d|
      # Bail out if deadline is reached.
      if get_time > deadline
        next
      end

      # Walk the front path one step.
      k1 = -d + k1start
      while k1 <= (d - k1end)
        k1_offset = v_offset + k1
        if k1 == -d || (k1 != d && (v1[k1_offset - 1] || 0) < (v1[k1_offset + 1] || 0))
          x1 = v1[k1_offset + 1]
        else
          x1 = v1[k1_offset - 1] + 1
        end
        y1 = x1 - k1
        while x1 < text1_length && y1 < text2_length && text1[x1] == text2[y1]
          x1 += 1
          y1 += 1
        end
        v1[k1_offset] = x1
        if x1 > text1_length
          # Ran off the right of the graph.
          k1end += 2
        elsif y1 > text2_length
          # Ran off the bottom of the graph.
          k1start += 2
        elsif front
          k2_offset = v_offset + delta - k1
          if k2_offset >= 0 && k2_offset < v_length && v2[k2_offset] != -1
            # Mirror x2 onto top-left coordinate system.
            x2 = text1_length - v2[k2_offset]
            if x1 >= x2
              # Overlap detected.
              return diff_bisect_split(text1, text2, x1, y1, deadline)
            end
          end
        end

        k1 += 2
      end

      # Walk the reverse path one step.
      k2 = (-d + k2start)
      while k2 <= (d - k2end)
        k2_offset = v_offset + k2
        if k2 == -d || (k2 != d && (v2[k2_offset - 1] || 0) < (v2[k2_offset + 1] || 0))
          x2 = v2[k2_offset + 1]
        else
          x2 = v2[k2_offset - 1] + 1
        end
        y2 = x2 - k2
        while x2 < text1_length && y2 < text2_length && text1[(text1_length - x2 - 1)] == text2[(text2_length - y2 - 1)]
          x2 += 1
          y2 += 1
        end
        v2[k2_offset] = x2
        if x2 > text1_length
          # Ran off the left of the graph.
          k2end += 2
        elsif y2 > text2_length
          # Ran off the top of the graph.
          k2start += 2
        elsif !front
          k1_offset = v_offset + delta - k2
          if k1_offset >= 0 && k1_offset < v_length && v1[k1_offset] != -1
            x1 = v1[k1_offset]
            y1 = v_offset + x1 - k1_offset
            # Mirror x2 onto top-left coordinate system.
            x2 = text1_length - x2
            if x1 >= x2
              return diff_bisect_split(text1, text2, x1, y1, deadline)
            end
          end
        end

        k2 += 2
      end
    end

    # Diff took too long and hit the deadline or
    # number of diffs equals number of characters, no commonality at all.
    [["DIFF_DELETE", text1], ["DIFF_INSERT", text2]]
  end

  def diff_bisect_split(text1, text2, x, y, deadline)
    text1_a = text1.substring(0, x)
    text2_a = text2.substring(0, y)
    text1_b = text1.substring(x)
    text2_b = text2.substring(y)

    diffs_a = diff_main(text1_a, text2_a, false, deadline)
    diffs_b = diff_main(text1_b, text2_b, false, deadline)

    diffs_a + diffs_b
  end

  def diff_common_overlap(text1, text2)
    # Cache the text lengths to prevent multiple calls.
    text1_length = text1.size
    text2_length = text2.size

    # Eliminate the null case.
    if text1_length == 0 || text2_length == 0
      return 0
    end

    # Truncate the longer string.
    if text1_length > text2_length
      text1 = text1.substring(text1_length - text2_length)
    elsif text1_length < text2_length
      text2 = text2.substring(0, text1_length)
    end
    text_length = [text1_length, text2_length].min
    # Quick check for the worst case.
    if text1 == text2
      return text_length
    end

    # Start by looking for a single character match
    # and increase length until no match is found.
    best   = 0
    length = 1
    while true
      pattern = text1.substring(text_length - length)
      found   = text2.index_of(pattern)
      if found == -1
        return best
      end
      length += found
      if found == 0 || text1.substring(text_length - length) == text2.substring(0, length)
        best = length
        length += 1
      end
    end
  end

  def diff_pretty_html(diffs)
    html = []
    diffs.each_with_index do |diff, index|
      op   = diff[0] # Operation (insert, delete and equal)
      data = diff[1] # Text of change
      text = data.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;").gsub(/\\n/, "&para;<br>")

      case op
      when "DIFF_INSERT" then html[index] = "<ins>#{text}</ins>"
      when "DIFF_DELETE" then html[index] = "<del>#{text}</del>"
      when "DIFF_EQUAL"  then html[index] = "<span>#{text}</span>"
      end
    end

    html.join("")
  end

  private

  # @return The number of milliseconds between midnight of January 1, 1970
  def get_time
    Time.now.strftime('%s%L').to_i
  end

  def max_number
    1.7976931348623157e+308
  end
end
