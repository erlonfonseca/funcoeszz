# ----------------------------------------------------------------------------
# Resultados da quina, megasena, duplasena, lotomania, lotofácil, federal, timemania e loteca.
#
# Se o 2º argumento for um número, pesquisa o resultado filtrando o concurso.
# Se o 2º argumento for a palavra "quantidade" ou "qtde" mostra quantas vezes
#  um número foi sorteado. ( Não se aplica para federal e loteca )
# Se nenhum argumento for passado, todas as loterias são mostradas.
#
# Uso: zzloteria [[loterias suportadas] [concurso|[quantidade|qtde]]
# Ex.: zzloteria
#      zzloteria quina megasena
#      zzloteria loteca 550
#
# Autor: Aurelio Marinho Jargas, www.aurelio.net
# Desde: 2004-05-18
# Versão: 15
# Licença: GPL
# Requisitos: zzlimpalixo
# Nota: requer links, unzip
# ----------------------------------------------------------------------------
zzloteria ()
{
	zzzz -h loteria "$1" && return

	local dump tipo num_con download qtde
	local url='http://loterias.caixa.gov.br/wps/portal/loterias/landing'
	local tipos='quina megasena duplasena lotomania lotofacil federal timemania loteca'
	local cache=$(zztool cache loteria)
	local tab=$(printf '\t')
	local un_zip='unzip -q -a -C -o'
	local tmp_dir="${ZZTMP%/*}"

	which links >/dev/null 2>&1 || {
		zztool erro 'Necessário instalar o navegador de modo texto "links" ou "links2".'
		return 1
	}

	download='links -source'

	# Caso o segundo argumento seja um numero, filtra pelo concurso equivalente
	if zztool testa_numero "$2"
	then
		tipos=$1
		num_con=$2
	elif test 'quantidade' = "$2" -o 'qtde' = "$2"
	then
		tipos=$1
		num_con=0
	else
		unset num_con
		test -n "$1" && tipos="$*"
	fi

	# Para cada tipo de loteria...
	for tipo in $tipos
	do

		# Para o caso de ser fornecido "lotofácil"
		tipo=$(echo "$tipo" | sed 's/á/a/')

		zztool eco "${tipo}:"
		if ! test -n "$num_con"
		then
			# Resultados mais recentes das loterias selecionadas.
			dump=$(zztool dump links "${url}/${tipo}" | sed -n '/Resultado Concurso/,/^ *Arrecada/p' | sed '2,6d;s/^Resultado //')
			case "$tipo" in
				lotomania | lotofacil)
					echo "$dump" |
					zzlimpalixo |
					awk '
						NR==1{print}
						/^ *[0-9 ]*$/{print}
						$1 ~ /Estimativa/ || $2 ~ /acertos/ {printf $0;getline;print}
						/^ *Acumulado/
					' |
					sed "
						/^ *Estimativa/ i \\

						/^ *20 acertos/ i \\

						/^ *15 acertos/ i \\

						s/ 0 /  0 /
						s/acertos */pts.${tab}/
						s/ *apostas\{0,1\} ganhadoras\{0,1\},/${tab}/
					" | expand -t 5,15,25
				;;
				megasena | duplasena | quina | timemania)
					echo "$dump" |
					zzlimpalixo |
					awk '
						NR==1{print}
						/ sorteio$/{print "";print}
						/^ *Premia/{print}
						$1 ~ /Estimativa/ {printf "\n\n" $0;getline;print}
						$NF ~ /acertados|Cora.*o$/ {printf $0;getline;print}
						/\/[A-Z]/ {getline; if ($0 ~ /^ *[0-9]+ /) {sub(/^ */,"");print "\t" $0} else print "\n\n" $0}
						/^ *Acumulado/
						/^ *Valor acumulado/
						/\* [0-9]/{printf $0}
					' |
					sed "
						s/^ *\([12]-o\)/  \1/
						s/  \* //g
						s/Premia[^0-9]*//
						s/ - [0-9]//
						s/n.meros acertados */pts.${tab}/
						s/ *apostas\{0,1\} ganhadoras\{0,1\},/${tab}/
						s/Time do Cora[^ ]*/ Time:/
						/Time/ i \\

					" |
					if test "$tipo" = "duplasena"
					then
						sed '2d;s/^\( *\)\([12]\)-\{0,1\}[oº]/  \2º/;s/a pts./a/;/º [Ss]orteio/ i \
'
					else
						sed 's/\([ao]\) pts./\1/'
					fi |
					expand -t 15,25,35
				;;
				federal)
					echo "$dump" | sed -n '1p;/^ *[1-5]-\{0,1\}[oº]/p;2s/.*//p;/^ *Destino/p' |
					sed 's/-o/º/;s/\([0-9.,]\{1,\}\) *$/R$ &/'
				;;
				loteca)
					echo "$dump" |
					sed -n '1p;/Coluna 1/,/^ *14/{s/[[:blank:]]*$//;p;}' |
					sed '
						2s/.*//
						3,${
							s/^ *//
							s/  */|/
							s/  */|/
							s/   */|/;
							s/[[:blank:]]\{1,\}\([0-9]\{1,\}\)[[:blank:]]\{1,\}\([^[:blank:]]\{1,\}\)$/|\1|\2/
						}' |
					awk -F "|" '
						NR==1
						NR==2 { printf " Jogo %66s\n", "Resultado" }
						NR>2 {
							printf " %2d  %23s %2d X %-2d %-23s  %8s\n", $1, $3, $2, $5, $4, "Col. " ($2==$5?"Meio":($2>$5?"1":"2"))}
					'
					echo "$dump" |
					awk '
						/Estimativa| acertos\)/ {printf $0;getline;print}
						/^ *Acumulado/
					' |
					sed "
						/^ *Estimativa/ i \\

						s/[12].*(//
						s/acertos) */pts.${tab}/
						s/ *apostas\{0,1\} ganhadoras\{0,1\},/${tab}/
					" |
					sed '/^ *14/ i \
'
				;;
			esac
			echo
		else
			# Resultados históricos das loterias selecionadas.
			case "$tipo" in
				lotomania)
					if ! test -e ${cache}.lotomania.htm || ! $(zztool dump ${cache}.lotomania.htm | grep "^ *$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_lotoma.zip" > "${cache}.lotomania.zip" 2>/dev/null
						$un_zip "${cache}.lotomania.zip" "*.HTM" -d "$tmp_dir" 2>/dev/null
						mv -f "${tmp_dir}/D_LOTMAN.HTM" ${cache}.lotomania.htm
						rm -f ${cache}.lotomania.zip
					fi
					zztool dump ${cache}.lotomania.htm |
					if test 0 = "$num_con"
					then
						awk '
						BEGIN { printf "## QTD\t## QTD\t## QTD\t## QTD\n" }
						$2 ~ /[0-9]\/[0-9][0-9]\/[0-9]/ { for (i=3;i<23;i++) numeros[$i]++ }
						END {
							for (i=0;i<25;i++) {
								num=sprintf("%02d",i)
								printf "%02d %d\t%02d %d\t%02d %d\t%02d %d\n", i, numeros[num], i+25, numeros[i+25], i+50, numeros[i+50], i+75, numeros[i+75]
							}
						}
						' | expand -t 10
					else
						grep "^ *$num_con " 2>/dev/null |
						tr -d '[A-Z]' |
						awk ' {
							print "Concurso", $1, "(" $2 ")"
							comando="sort -n | paste -d _ - - - - -"
							for (i=3;i<23;i++) {print $i | comando }
							close(comando)
							i=(NF==42?1:0)
							print ""
							printf "20 pts.\t%s\t%s\n", ($24==0?"Nao houve acertador!":$24), ($24==0?"":"R$ " $(NF-13+i))
							printf "19 pts.\t%s\t%s\n", $(NF-18+i), "R$ " $(NF-12+i)
							printf "18 pts.\t%s\t%s\n", $(NF-17+i), "R$ " $(NF-11+i)
							printf "17 pts.\t%s\t%s\n", $(NF-16+i), "R$ " $(NF-10+i)
							printf "16 pts.\t%s\t%s\n", $(NF-15+i), "R$ " $(NF-9+i)
							printf " 0 pts.\t%s\t%s\n", ($(NF-14+i)==0?"Nao houve acertador!":$(NF-14+i)), ($(NF-14+i)==0?"":"R$ " $(NF-8+i))
						}' | sed '/^[0-9 ]/s/^/   /;s/_/     /g' | expand -t 5,15,25
					fi
				;;
				lotofacil)
					if ! test -e ${cache}.lotofacil.htm || ! $(zztool dump ${cache}.lotofacil.htm | grep "^ *$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_lotfac.zip" > "${cache}.lotofacil.zip" 2>/dev/null
						$un_zip "${cache}.lotofacil.zip" "*.HTM" -d "$tmp_dir" 2>/dev/null
						mv -f "${tmp_dir}/D_LOTFAC.HTM" ${cache}.lotofacil.htm
						rm -f ${cache}.lotofacil.zip
					fi
					zztool dump ${cache}.lotofacil.htm |
					if test 0 = "$num_con"
					then
						awk '
						BEGIN { print "## QTD" }
						$2 ~ /[0-9]\/[0-9][0-9]\/[0-9]/ { for (i=3;i<18;i++) numeros[$i]++ }
						END {
							for (i=1;i<=25;i++) {
								num=sprintf("%02d",i)
								printf "%02d %d\n", i, numeros[num]
							}
						}
						' | expand -t 10
					else
						grep "^ *$num_con " 2>/dev/null |
						awk '{
							print "Concurso", $1, "(" $2 ")"
							comando="sort -n | paste -d _ - - - - -"
							for (i=3;i<18;i++) {print $i | comando }
							close(comando)
							print ""
							printf "15 pts.\t%s\t%s\n", ($19==0?"Nao houve acertador!":$19), ($19==0?"":"R$ " $(NF-7))
							printf "14 pts.\t%s\t%s\n", $(NF-11), "R$ " $(NF-6)
							printf "13 pts.\t%s\t%s\n", $(NF-10), "R$ " $(NF-5)
							printf "12 pts.\t%s\t%s\n", $(NF-9), "R$ " $(NF-4)
							printf "11 pts.\t%s\t%s\n", $(NF-8), "R$ " $(NF-3)
						}' | sed '/^[0-9 ]/s/^/   /;s/_/     /g' | expand -t 5,15,25
					fi
				;;
				megasena)
					if ! test -e ${cache}.mega.htm || ! $(zztool dump ${cache}.megasena.htm | grep "^ *$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_mgsasc.zip" > "${cache}.megasena.zip" 2>/dev/null
						$un_zip "${cache}.megasena.zip" "*.htm" -d "$tmp_dir" 2>/dev/null
						mv -f "${tmp_dir}/d_megasc.htm" ${cache}.megasena.htm
						rm -f ${cache}.megasena.zip
					fi
					zztool dump ${cache}.megasena.htm |
					if test 0 = "$num_con"
					then
						awk '
						BEGIN { printf "## QTD\t## QTD\t## QTD\n" }
						$2 ~ /[0-9]\/[0-9][0-9]\/[0-9]/ { for (i=3;i<9;i++) numeros[$i]++ }
						END {
							for (i=1;i<=20;i++) {
								num=sprintf("%02d",i)
								printf "%02d %d\t%02d %d\t%02d %d\n", i, numeros[num], i+20, numeros[i+20], i+40, numeros[i+40]
							}
						}
						' | expand -t 10
					else
						grep "^ *$num_con " 2>/dev/null |
						awk '{
							print "Concurso", $1, "(" $2 ")"
							printf "%4s %4s %4s %4s %4s %4s\n", $3, $4, $5, $6, $7, $8
							print ""
							printf "   Sena  \t%s\t%s\n", ($10==0?"Nao houve acertador!":$10), ($10==0?"":"R$ " $(NF-8))
							printf "   Quina \t%s\t%s\n", $(NF-7), "R$ " $(NF-6)
							printf "   Quadra\t%s\t%s\n", $(NF-5), "R$ " $(NF-4)
						}' | expand -t 15,25,35
					fi
				;;
				duplasena)
					if ! test -e ${cache}.duplasena.htm || ! $(zztool dump ${cache}.duplasena.htm | grep "^ *$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/d_dplsen.zip" > "${cache}.duplasena.zip" 2>/dev/null
						$un_zip "${cache}.duplasena.zip" "*.HTM" -d "$tmp_dir" 2>/dev/null
						mv -f "${tmp_dir}/D_DPLSEN.HTM" ${cache}.duplasena.htm
						rm -f ${cache}.duplasena.zip
					fi
					zztool dump ${cache}.duplasena.htm |
					if test 0 = "$num_con"
					then
						awk '
						BEGIN {
							printf "1º sorteio          2º sorteio\n"
							printf "## QTD\t## QTD\t## QTD\t## QTD\n"
							}
						$2 ~ /[0-9]\/[0-9][0-9]\/[0-9]/ {
							for (i=3;i<9;i++)  numeros1[$i]++
							for (i=15;i>9;i--) numeros2[$(NF-i) ]++
						}
						END {
							for (i=1;i<=25;i++) {
								num=sprintf("%02d",i)
								printf "%02d %d\t%02d %d\t%02d %d\t%02d %d\n", i, numeros1[num], i+25, numeros1[i+25], i, numeros2[num], i+25, numeros2[i+25]
							}
						}
						' | expand -t 10
					else
						grep "^ *$num_con " 2>/dev/null |
						awk '{
							print "Concurso", $1, "(" $2 ")"
							printf "\n  1º sorteio\n"
							comando="sort -n | paste -d _ - - - - - -"
							for (i=3;i<9;i++) {print $i | comando }
							close(comando)
							printf "\n  2º sorteio\n"
							for (i=15;i>9;i--) {print $(NF-i) | comando }
							close(comando)
							printf "\n  1º Sorteio\n"
							printf "   Sena  \t%s\t%s\n", ($10==0?"Nao houve acertador":$10), ($10==0?"":"R$ " $(NF-22))
							printf "   Quina \t%s\t%s\n", $(NF-21), "R$ " $(NF-20)
							printf "   Quadra\t%s\t%s\n", $(NF-19), "R$ " $(NF-19)
							printf "\n  2º Sorteio\n"
							printf "   Sena  \t%s\t%s\n", ($(NF-9)==0?"Nao houve acertador":$(NF-9)), ($(NF-9)==0?"":"R$ " $(NF-8))
							printf "   Quina \t%s\t%s\n", $(NF-7), "R$ " $(NF-6)
							printf "   Quadra\t%s\t%s\n", $(NF-5), "R$ " $(NF-4)
						}' | sed '/^[0-9][0-9]/s/^/   /;s/_/   /g'
					fi
				;;
				quina)
					if ! test -e ${cache}.quina.htm || ! $(zztool dump ${cache}.quina.htm | grep "^ *$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_quina.zip" > "${cache}.quina.zip" 2>/dev/null
						$un_zip "${cache}.quina.zip" "*.HTM" -d "$tmp_dir" 2>/dev/null
						mv -f "${tmp_dir}/D_QUINA.HTM" ${cache}.quina.htm
						rm -f ${cache}.quina.zip
					fi
					zztool dump ${cache}.quina.htm |
					if test 0 = "$num_con"
					then
						awk '
						BEGIN { printf "## QTD\t## QTD\t## QTD\t## QTD\n" }
						$2 ~ /[0-9]\/[0-9][0-9]\/[0-9]/ { for (i=3;i<8;i++) numeros[$i]++ }
						END {
							for (i=1;i<=20;i++) {
								num=sprintf("%02d",i)
								printf "%02d %d\t%02d %d\t%02d %d\t%02d %d\n", i, numeros[num], i+20, numeros[i+20], i+40, numeros[i+40], i+60, numeros[i+60]
							}
						}
						' | expand -t 10
					else
						grep "^ *$num_con " 2>/dev/null |
						awk '{
							print "Concurso", $1, "(" $2 ")"
							comando="sort -n | paste -d _ - - - - -"
							for (i=3;i<8;i++) {print $i | comando }
							close(comando)
							print ""
							printf "   Quina \t%s\t%s\n", ($9==0?"Nao houve acertador":$9), ($9==0?"":"R$ " $(NF-10))
							printf "   Quadra\t%s\t%s\n", $(NF-9), "R$ " $(NF-8)
							printf "   Terno \t%s\t%s\n", $(NF-7), "R$ " $(NF-6)
						}' | sed '/^[0-9][0-9]/s/^/   /;s/_/   /g' | expand -t 15,25,35
					fi
				;;
				federal)
					if test 0 = "$num_con"
					then
						zztool erro "Não se aplica a loteria federal."
						return 1
					fi

					if ! test -e ${cache}.federal.htm || ! $(zztool dump ${cache}.federal.htm | grep "^[ 0]*$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_federa.zip" > "${cache}.federal.zip" 2>/dev/null
						$un_zip "${cache}.federal.zip" "*.HTM" -d "$tmp_dir" 2>/dev/null
						mv -f "${tmp_dir}/D_LOTFED.HTM" ${cache}.federal.htm
						rm -f ${cache}.federal.zip
					fi
					zztool dump ${cache}.federal.htm |
					grep "^[ 0]*$num_con " 2>/dev/null |
					awk '{
						print "Concurso", $1, "(" $2 ")"
						print ""
						printf "   1º Premio     %s   %s\n", $3, "R$ " $8
						printf "   2º Premio     %s   %s\n", $4, "R$ " $9
						printf "   3º Premio     %s   %s\n", $5, "R$ " $10
						printf "   4º Premio     %s   %s\n", $6, "R$ " $11
						printf "   5º Premio     %s   %s\n", $7, "R$ " $12
					}'
				;;
				timemania)
					if ! test -e ${cache}.timemania.htm || ! $(zztool dump ${cache}.timemania.htm | grep "^ *$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/D_timasc.zip" > "${cache}.timemania.zip" 2>/dev/null
						$un_zip "${cache}.timemania.zip" "*.HTM" -d "$tmp_dir" 2>/dev/null
						mv -f "${tmp_dir}/D_TIMASC.HTM" ${cache}.timemania.htm
						rm -f ${cache}.timemania.zip
					fi
					zztool dump ${cache}.timemania.htm |
					if test 0 = "$num_con"
					then
						awk '
						BEGIN { printf "## QTD\t## QTD\t## QTD\t## QTD\n" }
						$2 ~ /[0-9]\/[0-9][0-9]\/[0-9]/ { for (i=3;i<10;i++) numeros[$i]++ }
						END {
							for (i=1;i<=20;i++) {
								num=sprintf("%02d",i)
								printf "%02d %d\t%02d %d\t%02d %d\t%02d %d\n", i, numeros[num], i+20, numeros[i+20], i+40, numeros[i+40], i+60, numeros[i+60]
							}
						}
						' | expand -t 10
					else
						grep "^ *$num_con " 2>/dev/null |
						sed 's/\([[:upper:]]\) \([[:upper:]]\)/\1_\2/g' |
						awk '{
							print "Concurso", $1, "(" $2 ")"
							printf "%5s %4s %4s %4s %4s %4s %4s\n", $3, $4, $5, $6, $7, $8, $9
							print ""
							printf "   7 pts.\t%s\t%s\n", ($12==0?"Nao houve acertador!":$12), ($12==0?"":"R$ " $(NF-7))
							printf "   6 pts.\t%s\t%s\n", $(NF-12), "R$ " $(NF-6)
							printf "   5 pts.\t%s\t%s\n", $(NF-11), "R$ " $(NF-5)
							printf "   4 pts.\t%s\t%s\n", $(NF-10), "R$ " $(NF-4)
							printf "   3 pts.\t%s\t%s\n", $(NF-9), "R$ " $(NF-3)
							printf "\n   Time: %s\t\n\t%s\t%s\n", $10, $(NF-8),  "R$ " $(NF-2)
						}' | expand -t 15,25,35
					fi
				;;
				loteca)
					if test 0 = "$num_con"
					then
						zztool erro "Não se aplica a loteca."
						return 1
					fi

					if ! test -e ${cache}.loteca.htm || ! $(zztool dump ${cache}.loteca.htm | grep "^ *$num_con " >/dev/null)
					then
						$download "http://www1.caixa.gov.br/loterias/_arquivos/loterias/d_loteca.zip" > "${cache}.loteca.zip" 2>/dev/null
						$un_zip "${cache}.loteca.zip" "*.HTM" -d "$tmp_dir" #2>/dev/null
						mv -f "${tmp_dir}/D_LOTECA.HTM" ${cache}.loteca.htm
						rm -f ${cache}.loteca.zip
					fi
					zztool dump ${cache}.loteca.htm |
					grep "^ *$num_con " 2>/dev/null |
					awk '{
						print "Concurso", $1, "(" $2 ")"
						print " Jogo   Resultado"
						printf "  1    %8s\n", "Col. " ($(NF-15)=="x"?"Meio":$(NF-15))
						printf "  2    %8s\n", "Col. " ($(NF-14)=="x"?"Meio":$(NF-14))
						printf "  3    %8s\n", "Col. " ($(NF-13)=="x"?"Meio":$(NF-13))
						printf "  4    %8s\n", "Col. " ($(NF-12)=="x"?"Meio":$(NF-12))
						printf "  5    %8s\n", "Col. " ($(NF-11)=="x"?"Meio":$(NF-11))
						printf "  6    %8s\n", "Col. " ($(NF-10)=="x"?"Meio":$(NF-10))
						printf "  7    %8s\n", "Col. " ($(NF-9)=="x"?"Meio":$(NF-9))
						printf "  8    %8s\n", "Col. " ($(NF-8)=="x"?"Meio":$(NF-8))
						printf "  9    %8s\n", "Col. " ($(NF-7)=="x"?"Meio":$(NF-7))
						printf " 10    %8s\n", "Col. " ($(NF-6)=="x"?"Meio":$(NF-6))
						printf " 11    %8s\n", "Col. " ($(NF-5)=="x"?"Meio":$(NF-5))
						printf " 12    %8s\n", "Col. " ($(NF-4)=="x"?"Meio":$(NF-4))
						printf " 13    %8s\n", "Col. " ($(NF-3)=="x"?"Meio":$(NF-3))
						printf " 14    %8s\n", "Col. " ($(NF-2)=="x"?"Meio":$(NF-2))
						print ""
						printf "  14 pts.\t%s\t%s\n", ($3==0?"Nao houve acertador":$3), ($3==0?"":"R$ " $(NF-21))
						printf "  13 pts.\t%s\t%s\n", $(NF-18), "R$ " $(NF-17)
					}'
				;;
			esac
			echo
		fi
	done
}
