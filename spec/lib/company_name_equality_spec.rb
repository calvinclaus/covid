require 'rails_helper'
require_relative '../../lib/company_name_equality/company_name_equality.rb'


RSpec.describe "CompanyNameEquality" do
  def e(c1, c2)
    expect(CompanyNameEquality.same_company?(c1, c2)).to eq(true), "expected #{c1} === #{c2}"
    expect(CompanyNameEquality.same_company?(c2, c1)).to eq(true), "expected #{c1} === #{c2}"
  end

  def ne(c1, c2)
    expect(CompanyNameEquality.same_company?(c1, c2)).to eq(false), "expected #{c1} !== #{c2}"
    expect(CompanyNameEquality.same_company?(c2, c1)).to eq(false), "expected #{c1} !== #{c2}"
  end

  it "can do a lot" do
    header, *rows = CSV.parse(File.read('fixtures/csvs/company_name_equality/thomas-blacklist.csv'), encoding: "UTF-8")
    blacklist = rows.map{ |r| r[0] }

    header, *rows = CSV.parse(File.read('fixtures/csvs/company_name_equality/thomas-search-results.csv'), encoding: "UTF-8")
    check_against = rows.map{ |r| r[header.find_index('companyName')] }

    size_before = check_against.size
    blacklist = blacklist.map{ |n| CompanyNameEquality.clean_name(n) }
    check_against = check_against.map{ |n| CompanyNameEquality.clean_name(n) }

    check_against = check_against.reject do |company_to_check_if_on_blacklist|
      blacklist.any? do |blacklist_item|
        CompanyNameEquality.same_company?(blacklist_item, company_to_check_if_on_blacklist, cleaned: true)
      end
    end

    expect(size_before - check_against.size).to eq(51)
  end

  it "just one" do
    e("Christian Prokopp GmbH", "Prokopp")
  end

  it "know if two companies equal" do
    # These cases are all my phantasy

    e("M+K Wien Werbeagentur GmbH", "M+K Wien")
    e("My Sugar", "My Sugar")
    e("Anyline", "Anyline")
    e("CREATE 21.st century", "Create 21st")
    e("CREATE 21.st century", "Create 21 st")
    e("Docfinder GmbH.", "DocFinder")
    e("Frux Technologies GmbH", "FRUX")
    e("Frux Technologies GmbH", "FRUX GmbH")
    e("Amgen Austria Foobar", "Amgen Austria Foobar")
    e("Amgen Austria", "Amgen Germany")
    e("SAP Technologies", "SAP Something Something Something Something")
    e("XXXLutz KG", "XXXLutz Holding")
    e("Frux Software Solutions Pvt.Ltd.,", "FrUx")
    e("Amgen Austria", "Amgen Holding")
    e("Wirecard Central Eastern Europe", "Wirecard CEE")
    e("ORF-Enterprise GmbH & Co KG", "ORF GmbH & Co KG")
    e("ORF-Enterprise GmbH & Co KG", "ORF")
    e("Österreichische Post", "Post")
    e("AT-Post", "Post")
    e("DE-Post", "Post")
    e("KNAPP AG", "KNAPP Industry Solutions")
    e("KNAPP AG", "KNAPP System Integration")
    e("KNAPP Industry Solutions", "KNAPP System Integration")
    e("backaldrin The Kornspitz Company GmbH", "backaldrin International The Kornspitz Company GmbH")
  end

  it "tolerated failures" do
    e("AT-Post", "DE-Post")
    e("Österreichische Post", "Deutsche Post")
    e("Immobilien Scout 24", "Immobilien Scout Oberdorf")
    e("Karl Zotter - Happy Sound", "Zotter")
    e("HIRSCH Servo AG", "Hirsch GmbH")
    e("Hubers Boutiquehotel", "Huber")
    e("Heinz Huber Rohrleitungsbau", "Huber")
    e("HUBER SKI-CON KG", "Huber")
    e("e7 Energie Markt Analyse GmbH", "Energie AG Oberösterreich")
  end

  it "knows if two companies are not equal" do
    ne("DailyDeal GmbH", "DailyMeal GmbH")
    ne("E Rejuvenation", "E Foobar")
    ne("´Biogest Energie- und Wassertechnik GmbH", "Energie AG Oberösterreich")
    ne("Biogest Energie- und Wassertechnik GmbH", "Energie AG Oberösterreich")
    ne("M+K Wien Werbeagentur GmbH", "Wien Strom")
  end

  it "can deal with ()" do
    e("FRUX", "FRUX")
    e("FRUX (some gibberish)", "FRUX")
  end

  it "can deal with thomas hofstaetter equalities" do
    e("Anyline",  "Anyline GmbH")
    ne("Bene", "Benefit Partner GmbH")
    ne("Bene GmbH", "Benefit Partner GmbH")
    ne("Mehrenergie Consulting", "Energie AG Oberösterreich")
    ne("IDM Energiesysteme GmbH", "Energie AG Oberösterreich")
    e("Canon Austria GmbH",  "Canon Austria GmbH")
    e("Canon Austria GmbH",  "Canon Austria GmbH")
    e("Canon Austria GmbH",  "Canon Austria GmbH")
    e("Cards & Systems EDV-Dienstleistungs GmbH",  "Cards & Systems EDV-Dienstleistungs GmbH")
    e("Cards & Systems EDV‑Dienstleistungs GmbH",  "Cards & Systems EDV-Dienstleistungs GmbH")
    e("CRIF",  "CRIF GmbH")
    e("CRIF", "CRIF GmbH")
    e("CRIF", "CRIF GmbH")
    e("dataformers GmbH", "dataformers GmbH")
    ne("RAIN", "DCA Training GmbH Dale Carnegie Austria")
    e("DocFinder GmbH", "Docfinder GmbH.")
    ne("Kelag Energie", "Energie AG Oberösterreich")
    ne("KELAG Energie & Wärme GmbH", "Energie AG Oberösterreich")
    ne("HERZ Energietechnik GmbH", "Energie AG Oberösterreich")
    ne("Energieversorgung Kleinwalsertal", "Energie AG Oberösterreich")
    ne("Seidl Energietechnik e. U.", "Energie AG Oberösterreich")

    ne("Software AG", "falcana Software GmbH")
    ne("Software AG", "falcana Software GmbH")
    e("Software AG", "Software AG")
    e("Software AG", "Software AG.")
    e("Software AG", "Software GmbH")

    e("GEKKO it-solutions GmbH", "Gekko it-solutions GmbH")
    e("Greenbird Vertriebs GmbH", "Greenbird Vertriebs GmbH")
    e("hotelkit GmbH", "hotelkit GmbH")
    e("icomedias", "icomedias GmbH")
    e("Kapsch BusinessCom AG", "Kapsch BusinessCom AG")
    e("Kapsch AG", "Kapsch BusinessCom AG")

    ne("ERCO", "Kapsch CarrierCom AG")

    e("McWERK GmbH", "McWERK GmbH")

    ne("Infoniqa Payroll Holding GmbH", "NFON GmbH")
    ne("Infoniqa", "NFON GmbH")

    e("REPULS LichtMedizinTechnik Austria GmbH", "REPULS Lichtmedizintechnik GmbH")
    e("SBA Research", "SBA Research GmbH")
    e("SIX Payment Services", "SIX Payment Services (Austria) GmbH")
    e("Waytation", "waytation - web architects e.U.")
  end

  it "can deal with finnest inequalities" do
    e("SAMINA Produktions- und Handels GmbH", "Samina")
    ne("Biogen", "Biogena")
    e("Biogena Gastronomie GmbH", "Biogena")
    ne("Lichtenstrasser Brillen GmbH", "Strasser")
    e("Strasser & Karl GmbH", "Strasser")
    e("Resch GmbH und CO KG", "Resch & Frisch")
    ne("Wolf GmbH u Co KG", "Wolford")
    ne("Berger", "Wienerberger")
    ne("Erber GmbH - Der Tiroler Edelbrenner", "Wienerberger")
    ne("wien", "Wienerberger")
    e("VAMED AG", "VAMED")
    e("VAMED", "VAMED")
    e("Vamed Management & Service", "VAMED")
    e("VAMED KMB", "VAMED")
    e("VAMED Krankenhausmanagement und Projekt GmbH", "VAMED")
    e("VAMED Management und Service GmbH", "VAMED")
    e("VAMED Standortentwicklung und Engineering GmbH", "VAMED")
    e("Vamed", "VAMED")
    e("Holmes Place", "Holmes Place")
    e("Christian Prokopp GmbH", "Prokopp")
    e("Gewußt wie wellness & beauty e. Gen.", "Gewusst wie Drogerie")
    e("SONNENTOR", "Sonnentor")
    e("Leo Hillinger in der Schrannenhalle", "Hillinger")
    e("HIRSCH The Bracelet", "Hirsch GmbH")
    ne("Birnhirsch Likörmanufaktur", "Hirsch GmbH")
    e("Hirsch Armbaender GmbH", "Hirsch GmbH")
    e("Schwarz Hirsch", "Hirsch GmbH")
    ne("Hirschbichler Wallegg GmbH", "Hirsch GmbH")
    ne("Steppenhirsch - Wild ist der Osten", "Hirsch GmbH")
    ne("Semmering Hirschenkogel Bergbahnen GmbH", "Hirsch GmbH")
    ne("Platzhirsch", "Hirsch GmbH")
    ne("hubergroup Austria GmbH", "Huber")
    ne("Weishuber & Hofer OG", "Huber")
    ne("Huberbräu", "Huber")
    ne("Hörtenhuber Edelstahl GmbH & CoKg", "Huber")
    e("Huber Einkauf GmbH & Co. KG", "Huber")
    e("Huber Trans GmbH & CoKG", "Huber")
    ne("schuh", "Richter Schuhe")
    e("Brauerei Hirt Ges.m.b.H", "Brauerei Hirt")
    ne("Auer GmbH", "Brauerei Hirt")
    e("Brauerei Hirt Ges.m.b.H", "Brauerei Hirt")
    e("Brauerei", "Brauerei Hirt")
    ne("Auer GmbH & CoKG", "Brauerei Hirt")
    ne("Harrys Homes Hotels", "Hotel")
  end

  it "spanish" do
    ne("GRUPO CATALANA OCCIDENTE",  "Grupo Deporocio")
  end
end
