module PragmaticSegmenter
  module Languages
    class Deutsch < Common
      ABBREVIATIONS = ['Ä', 'ä', 'adj', 'adm', 'adv', 'art', 'asst', 'b.a', 'b.s', 'bart', 'bldg', 'brig', 'bros', 'bse', 'buchst', 'bzgl', 'bzw', 'c.-à-d', 'ca', 'capt', 'chr', 'cmdr', 'co', 'col', 'comdr', 'con', 'corp', 'cpl', 'd.h', 'd.j', 'dergl', 'dgl', 'dkr', 'dr ', 'ens', 'etc', 'ev ', 'evtl', 'ff', 'g.g.a', 'g.u', 'gen', 'ggf', 'gov', 'hon', 'hosp', 'i.f', 'i.h.v', 'ii', 'iii', 'insp', 'iv', 'ix', 'jun', 'k.o', 'kath ', 'lfd', 'lt', 'ltd', 'm.e', 'maj', 'med', 'messrs', 'mio', 'mlle', 'mm', 'mme', 'mr', 'mrd', 'mrs', 'ms', 'msgr', 'mwst', 'no', 'nos', 'nr', 'o.ä', 'op', 'ord', 'pfc', 'ph', 'pp', 'prof', 'pvt', 'rep', 'reps', 'res', 'rev', 'rt', 's.p.a', 'sa', 'sen', 'sens', 'sfc', 'sgt', 'sog', 'sogen', 'spp', 'sr', 'st', 'std', 'str  ', 'supt', 'surg', 'u.a  ', 'u.e', 'u.s.w', 'u.u', 'u.ä', 'usf', 'usw', 'v', 'vgl', 'vi', 'vii', 'viii', 'vs', 'x', 'xi', 'xii', 'xiii', 'xiv', 'xix', 'xv', 'xvi', 'xvii', 'xviii', 'xx', 'z.b', 'z.t', 'z.z', 'z.zt', 'zt', 'zzt']
      NUMBER_ABBREVIATIONS = ['art', 'ca', 'no', 'nos', 'nr', 'pp']

      # Rubular: http://rubular.com/r/OdcXBsub0w
      BETWEEN_UNCONVENTIONAL_DOUBLE_QUOTE_DE_REGEX = /,,(?>[^“\\]+|\\{2}|\\.)*“/

      # Rubular: http://rubular.com/r/2UskIupGgP
      SPLIT_DOUBLE_QUOTES_DE_REGEX = /\A„(?>[^“\\]+|\\{2}|\\.)*“/

      # Rubular: http://rubular.com/r/TkZomF9tTM
      BETWEEN_DOUBLE_QUOTES_DE_REGEX = /„(?>[^“\\]+|\\{2}|\\.)*“/

      # Rubular: http://rubular.com/r/hZxoyQwKT1
      NumberPeriodSpaceRule = Rule.new(/(?<=\s[0-9]|\s([1-9][0-9]))\.(?=\s)/, '∯')

      # Rubular: http://rubular.com/r/ityNMwdghj
      NegativeNumberPeriodSpaceRule = Rule.new(/(?<=-[0-9]|-([1-9][0-9]))\.(?=\s)/, '∯')

      MONTHS = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']

      # Rubular: http://rubular.com/r/B4X33QKIL8
      SingleLowerCaseLetterRule = Rule.new(/(?<=\s[a-z])\.(?=\s)/, '∯')

      # Rubular: http://rubular.com/r/iUNSkCuso0
      SingleLowerCaseLetterAtStartOfLineRule = Rule.new(/(?<=^[a-z])\.(?=\s)/, '∯')


      class Process < PragmaticSegmenter::Process
        private

        def between_punctuation(txt)
          BetweenPunctuation.new(text: txt).replace
        end

        def replace_numbers(txt)
          Number.new(text: txt).replace
        end

        def replace_abbreviations(txt)
          AbbreviationReplacer.new(text: txt, abbr: Abbreviation).replace
        end
      end

      class Cleaner < PragmaticSegmenter::Cleaner
        private

        def abbreviations
          ABBREVIATIONS
        end
      end

      class Number < PragmaticSegmenter::Number
        def replace
          super
          @text.apply(NumberPeriodSpaceRule, NegativeNumberPeriodSpaceRule)
          replace_period_in_deutsch_dates(@text)
        end

        def replace_period_in_deutsch_dates(txt)
          MONTHS.each do |month|
            # Rubular: http://rubular.com/r/zlqgj7G5dA
            txt.gsub!(/(?<=\d)\.(?=\s*#{Regexp.escape(month)})/, '∯')
          end
          txt
        end
      end

      module Abbreviation
        def self.all
          ABBREVIATIONS
        end

        def self.prepositive
          []
        end

        def self.number
          NUMBER_ABBREVIATIONS
        end
      end

      class AbbreviationReplacer  < PragmaticSegmenter::AbbreviationReplacer
        def replace
          @reformatted_text = text.apply(
            Languages::Common::PossessiveAbbreviationRule,
            Languages::Common::SingleLetterAbbreviationRules::All,
            SingleLowerCaseLetterRule,
            SingleLowerCaseLetterAtStartOfLineRule)

          @reformatted_text = search_for_abbreviations_in_string(@reformatted_text, abbreviations)
          @reformatted_text = replace_multi_period_abbreviations(@reformatted_text)
          @reformatted_text = @reformatted_text.apply(Languages::Common::AmPmRules::All)
          replace_abbreviation_as_sentence_boundary(@reformatted_text)
        end

        private

        def scan_for_replacements(txt, am, index, character_array, abbr)
          replace_abbr(txt, am)
        end

        def replace_abbr(txt, abbr)
          txt.gsub(/(?<=#{abbr})\.(?=\s)/, '∯')
        end
      end

      class BetweenPunctuation < PragmaticSegmenter::BetweenPunctuation
        private

        def sub_punctuation_between_double_quotes(txt)
          btwn_dbl_quote = sub_punctuation_between_double_quotes_de(txt)
          PragmaticSegmenter::PunctuationReplacer.new(
            matches_array: btwn_dbl_quote,
            text: txt
          ).replace
        end

        def sub_punctuation_between_double_quotes_de(txt)
          if txt.include?('„')
            btwn_dbl_quote = txt.scan(BETWEEN_DOUBLE_QUOTES_DE_REGEX)
            txt.scan(SPLIT_DOUBLE_QUOTES_DE_REGEX).each do |q|
              btwn_dbl_quote << q
            end
          elsif txt.include?(',,')
            btwn_dbl_quote = txt.scan(BETWEEN_UNCONVENTIONAL_DOUBLE_QUOTE_DE_REGEX)
          end
          btwn_dbl_quote
        end
      end
    end
  end
end
