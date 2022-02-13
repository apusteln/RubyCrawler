require 'nokogiri'
require 'open-uri' #used to get html
require 'byebug' #debuger in terminal - usuń wszystkie byebugi przed oddaniem
require 'sequel'
require 'sqlite3'

# listing?string=motopompy
# https://allegro.pl/kategoria/nawadnianie-pompy-i-hydrofory-85214
#"https://www.amazon.pl/"
# https://www.amazon.pl/gp/bestsellers/grocery/ref=zg_bs_pg_2?ie=UTF8&pg=2 #2nd page of results
# first_product.css('a.a-link-normal').text
# products[1].css('a.a-size-small').text get review count
# products[1].css('span.a-icon-alt').text get review score
# products[1].css('a.a-link-normal')[0].text.strip get name
# products[1].css('a.a-text-normal').text get price !important you have to iterate over products to avoid shifting indexes of prices and reviews in relation to names
# doc.at_css('a:contains("Następna")')["href"] find next page button link
# doc.at_css('a:contains("Następna")') == nil check for next page
# doc.at_css('a:contains("Dalej")')["href"] this gives /s?k=motopompy+karcher&page=2&qid=1644541148&ref=sr_pg_1
# TODO - convert polish characters to ascii


def get_price(product)
    price = product.css('span.a-offscreen').text
    return price
end

def get_name(product)
    name = product.css('div.a-section.a-spacing-none.a-spacing-top-small.s-title-instructions-style').text.strip
    return name
end

def get_score(product)
    score = product.css('span.a-declarative').text
    review_count = product.css('span.a-size-base.s-underline-text').text
    return score, review_count
end

def get_details(product)
    link = "https://www.amazon.pl" + product.at_css('a.a-link-normal.s-underline-text.s-underline-link-text.s-link-style.a-text-normal')["href"]
    doc = Nokogiri::HTML(URI.open(link, "User-Agent" => "").read)
    details = doc.css('div#feature-bullets.a-section.a-spacing-medium.a-spacing-top-small').text.strip
    return details, link
end

def save_to_db(items, file_name="database.db")
    
    if(File.file?(file_name))
        puts "Plik " + file_name + " już istnieje"
        if file_name.split(".")[0].scan( /\d+$/ ).first
            num = Integer(file_name.split(".")[0].scan( /\d+$/ ).first)
            next_num = num + 1
            file_name = file_name.sub(/.*\K#{String(num)}/, String(next_num))
            while File.file?(file_name) or File.file?(file_name + ".db")
                next_num = next_num + 1
                file_name = file_name.sub(/.*\K#{String(num)}/, String(next_num))
            end
        else
            num = 1
            new_file_name = file_name.split(".")[0] + "_" + String(num)
            while File.file?(new_file_name) or File.file?(new_file_name + ".db")
                num = num + 1
                new_file_name = file_name.split(".")[0] + "_" + String(num)
            end
            file_name = new_file_name
        end
        puts "Czy chcesz utworzyć plik o nazwie " + file_name + ".db [y/n]?"
        ans = gets.chomp
        while !(["Y", "N", "y", "n"].include? ans)
            puts "Proszę wprowadzić y lub n"
            ans = gets.chomp
        end
        if ["N", "n"].include? ans
            puts "Proszę dogodną nazwę bazy danych: "
            ans = gets.chomp
            while ans.match(/\s/)
                puts "Nazwa pliku nie może zawierać białych znaków, prosze podać inną nazwę bazy danych: "
                ans = gets.chomp
            end
            file_name = ans
        end
        if !file_name.end_with?(".db")
            file_name = file_name + ".db"
        else
            file_name = file_name
        end
    end
    
    puts "Plik bazy danych '" + file_name + " zostanie utworzony w folderze " + Dir.pwd
    
    db = Sequel.sqlite(file_name)
    db.create_table :items do
        primary_key :id
        String :nazwa, null: false
        String :cena, null: false
        String :recenzje, null: false
        String :ilość_recenzji, null: false
        String :informacje, null: false
        String :link, null: false
    end
    table = db[:items]
    for item in items
        table.insert(nazwa: item[0], cena: item[1], recenzje: item[2][0], ilość_recenzji: item[2][1], informacje: item[3][0], link: item[3][1])
    end
    puts "Ilość znalezionych i zapisanych pozycji: #{table.count}"
end

def main_crawler
    puts "Przeglądasz amazon.pl, proszę podać szukane frazy:"
    user_input = gets.chomp.strip.split.join("+")
    puts "Wprowadzone frazy: " + user_input
    puts "Ile produktów chcesz zczytać? (Więcej niż 50 może powodować timeout)"
    search_count = gets.chomp
    search_count = Integer(search_count) rescue false
    while not search_count
        puts "Nie odczytano liczby, prosze wprowadzić liczbę dziesiętną: "
        search_count = gets.chomp
        search_count = Integer(search_count) rescue false
    end
    url = "https://www.amazon.pl/s?k=" + user_input
    doc = Nokogiri::HTML(URI.open(url, "User-Agent" => "").read) #no user agent needed for amazon?
    products = doc.css('div.a-section.a-spacing-small.s-padding-left-small.s-padding-right-small')
    items = []
    while true
        for product in products
            product_name = get_name(product)
            if product_name.strip.end_with?("Prześlij opinię na temat reklamy" or product_name.strip.end_with?("Prześlij opinię na temat reklamy." or product_name.strip.end_with?("produkt pasuje do Twojego zapytania."
                next
            end
            phrase_to_remove = "opinię na temat reklamy"
            if product_name.include?(phrase_to_remove)
                product_name.gsub!(/.*?(?=@#{phrase_to_remove})/im, "").lstrip
            end
        
            product_price = get_price(product)
            
            product_score, product_num_reviews = get_score(product)
            phrase_to_remove = "opinię na temat reklamy"
            if product_score.include?(phrase_to_remove)
                product_score.gsub!(/.*?(?=@#{phrase_to_remove})/im, "").lstrip
            end
            
            product_details, product_link = get_details(product)
            
            items.append([product_name, product_price, product_score, product_num_reviews, product_details, product_link])
            
            if items.length >= search_count
                save_to_db(items)
                byebug
                return
            end
        end
        if doc.at_css('a:contains("Dalej")') == nil
            break
        else
            url = "https://www.amazon.pl" + doc.at_css('a:contains("Dalej")')["href"]
            doc = Nokogiri::HTML(URI.open(url, "User-Agent" => "").read)
            products = doc.css('div.a-section.a-spacing-small.s-padding-left-small.s-padding-right-small')
        end
    end
    if items.length == 0
        puts "Nie znaleziono żadnych produktów"
    else
        save_to_db(items)
    end
end

main_crawler
