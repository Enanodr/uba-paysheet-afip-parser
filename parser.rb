require 'yomu'
require 'byebug'

# puts "Escribi el path donde estan tus recibos de sueldo en formato pdf."
# inp = gets
# inp << '/' unless inp.end_with?('/')
file_path = '/home/diego/Documents/recibos/'

code_line_parser = Proc.new { |line| amount_from(line.split(" ").last) }
total_line_parser = Proc.new { |line| amount_from(line.split(' ')[2]) }
KNOWN_CODES = {
    "APORTES OBRA SOCIAL": { parser: code_line_parser , codes: ['210', '214', '207'] },
    "APORTES SEGURIDAD SOCIAL": { parser: code_line_parser , codes: ['201', '247', '272'] },
    "EXCENTO EN GANANCIAS": { parser: code_line_parser , codes: ['234'] },
    "IMPORTE RETRIBUCIONES NO HABITUALES": { parser: code_line_parser , codes: ['168', '169'] },
    "APORTE SINDICAL": { parser: code_line_parser , codes: ['273'] },
    "SAC": { parser: code_line_parser , codes: ['123'] },
    "IMPORTE RETENCIONES GANANCIAS SUFRIDAS": { parser: nil , codes: [] },
    "AJUSTES": { parser: nil , codes: [] },
    "IMPORTE CONCEPTOS EXTENTOS / NO ALCANZADOS EN GANANCIAS": { parser: nil , codes: [] },
    "IMPORTE GANANCIAS BRUTAS": { parser: total_line_parser , codes: ["TOTAL HABERES"] }
}
PERIOD_TAG = "Periodo:"
    
def print_periods(periods)
    periods.sort.each do |period, values|
        puts "  "
        puts "  "
        puts "  "
        puts "################ "
        puts "#{period.upcase}"
        puts "################ "
        values.each do |category, value|
            puts "#{category.upcase}: #{value}"
        end
        puts "################ "
    end 
end

def amount_from(string_number)
    number = string_number.gsub('$', '')
    
    # Case where the number is (XXX), then is negative
    if number.start_with?('(')
        number = number.gsub('(','-').gsub(')','')
    end
    number.gsub(".","").gsub(",",".").to_f
end

def fill_period_taxes(code_amounts, lines)
    lines.each do |line|
        KNOWN_CODES.keys.each do |key|
            KNOWN_CODES[key][:codes].each do |code|
                code_amounts[key] += KNOWN_CODES[key][:parser].call(line)  if line.start_with?(code)
            end
        end
    end
end

monthly_taxes = {}

Dir.entries(file_path).reject { |file| file.start_with? "." }
                      .each do |file|
    puts "PARSEANDO #{file}" 
    raw_text = Yomu.new("#{file_path}#{file}").text
    non_empty_lines = raw_text.split("\n")
                              .map { |line| line.strip }
                              .select { |line| !line.empty?  }
                                          
    # set black period tax hash
    code_amounts = {}
    KNOWN_CODES.keys.each do |key|
        code_amounts[key] = 0
    end
    
    period = non_empty_lines.find do |line|
        line.start_with? PERIOD_TAG
    end
    puts "PERIODO #{period}"

    # Continue using period tax if another exists
    if monthly_taxes[period]
        code_amounts = monthly_taxes[period]
        puts "PERIODO REPETIDO"
    end

    fill_period_taxes(code_amounts, non_empty_lines)
    
    monthly_taxes[period] = code_amounts
end

print_periods monthly_taxes