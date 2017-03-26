require 'securerandom'

class PasswordGenerator

    attr_accessor :size, :mnemonic

    def initialize(params = {})

        @lowercase_chars = ('a'..'z').to_a
        @uppercase_chars = @lowercase_chars.map{|w| w.upcase}
        @numbers_chars   = ("0".."9").to_a
        @extra_chars     = %w(_ : ! ? # ~ @ . , % ; $ & ^ * = > < / { } +  | [ ])

        # get the parameter size and convert it into integer value

        @size      = params[:size].to_i

        @lowercase = params[:lowercase]
        @uppercase = params[:uppercase]
        @numbers   = params[:numbers]
        @extra     = params[:extra]

        @mistake    = params[:mistake]
        @url_unsafe = params[:url_unsafe]

        @mnemonic = params[:mnemonic]

        @size = Random.rand(6..20) unless @size and @size > 0
    end

    def generate

        @final_array = Array.new

        @final_array += @lowercase_chars if @lowercase
        @final_array += @uppercase_chars if @uppercase
        @final_array += @numbers_chars   if @numbers
        @final_array += @extra_chars     if @extra

        # remove mistaken characters

        @final_array -= %w(i I o O 0 1 l) if @mistake

        # remove characters unsafe for urls

        @final_array -= %w($ & + , / : ; = ? @ < > # % { } | ^ ~ [ ]) if @url_unsafe

        # Checks if no parameter was inserted, if true generate a
        # random password with lowercase chars

        @final_array += @lowercase_chars if @final_array.empty?

        # let's now pass the array which contains all the chars
        # to the method which will generate out password

        final_password = String.new

        @size.times do |x|
            final_password += get_random(@final_array).to_s
        end

        return final_password
    end

    def generate_mnemonic
        lists = Array.new
        string_generated = String.new

        words_used = Array.new
        random_words = Array.new

        lists_exist = false

        # check if the directory which contains all the word lists is empty

        if File.directory? @mnemonic
            Dir.foreach(@mnemonic + '/') do |item|
                if item != '..' and item != '.'

                    # push all the words contained into the word lists into the array "lists"

                    lists.push(IO.read("#{@mnemonic}/#{item}").force_encoding("ISO-8859-1").encode("utf-8", replace: nil).split(" "))

                    lists_exist = true
                end
            end
        else
            raise "Can't generate mnemonic passwords without a word list directory!"
        end

        raise "Directory doesn't contain any word lists!" unless lists_exist

        # get the random element from the array "lists" and add it to
        # the final string which contains the future password.

        lists.each do |word|
            element = get_random(word)

            single_element = element[0..Random.rand(3..element.size)]

            random_words.push(single_element)

            # the word used for the string_generated will also be cut
            # on random positions

            string_generated += single_element
        end

        string_generated = string_generated[0...@size].downcase
        string_to_cut = string_generated.dup

        # the following algorithm checks the words used into the
        # final password and push them into a new array

        random_words.each do |word|
            if string_to_cut =~ /#{word}/mi
                words_used.push(word)
                string_to_cut.slice!(/#{word}/i)
            end
        end

        # push the ramaining (probably meaningless) words

        words_used.push(string_to_cut)

        # all the characters of string_generated have been converted in down case
        # and the string was resized according to the parameters of the class @size

        # string_generated will be partially converted to upper case
        # if the parameter @uppercase is set

        if @uppercase
            string_generated.size.times do |x|
                if (x % 5) == 0 then string_generated[x] = string_generated[x].upcase end
            end
        end

        # remove the url unsafe characters if parameter was set

        @extra_chars -= %w($ & + , / : ; = ? @ < > # % { } | ^ ~ [ ]) if @url_unsafe

        # if the parameter @extra was set, will be added to the string, two
        # special chars, same thing will be done for for the option @numbers
        # adding to the string a number generated randomly from 100 to 500

        if @extra
            string_generated = get_random(@extra_chars) + string_generated + get_random(@extra_chars)
        end

        if @numbers
            string_generated += Random.rand(100...500).to_s
        end

        return string_generated, words_used
    end

    def extended(password)

        mnemonics = %w(
            alpha  bravo    charlie delta  echo   foxtrot
            golf   hotel    india   juliet kilo   lima
            mike   november oscar   papa   quebec romeo
            sierra tango    uniform victor whisky x-ray
            yankee zulu
        )

        last_words = Array.new

        password.each_char do |chars|
            @lowercase_chars.each_with_index do |x, i|
                if chars == @uppercase_chars[i]
                    last_words.push(mnemonics[i].upcase)
                end

                if chars == x
                    last_words.push(mnemonics[i])
                end
            end

            @numbers_chars.each do |numbers|
                if chars == numbers.to_s
                    last_words.push(numbers.to_s)
                end
            end

            @extra_chars.each do |x|
                if chars == x
                    last_words.push(x)
                end
            end
        end

        return last_words
    end

    def get_random(array_to_select)
        array_to_select[SecureRandom.random_number(array_to_select.size)]
    end

    def self.version
        '0.1.2'
    end
end
