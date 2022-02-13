# RubyCrawler

Prosty skrypt w ruby przeszukujący stronę amazon.pl używając podanych przez użytkownika haseł wyszukiwania.
Hasła nie mogą posiadać polskich znaków.

Skrypt prosi o ilość produktów do zapisania i zczytuje szczegółowe dane zgodnie z kolejnością na amazon.pl.

Zapisuje następujące dane:
- Nazwa produktu
- Cena produktu
- Ilość gwiazdek
- Ilość recenzji
- Szczegółowy opis produktu
- Link do strony produktu

Skrypt zapisze bazę danych przy pomocy sqlite3 do pliku "database.db" w folderze roboczym.

Skrypt wymaga zainstalowania następujących gemów:
- nokogiri
- open-uri
- sequel
- sqlite3

Skrypt znajduje się w pliku 'crawler.rb' i nie pobiera żadnych argumentów, o hasła oraz inne dane prosi promptami.

`ruby ./crawler.rb`
