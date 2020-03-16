require 'rails_helper'
require_relative '../../lib/human_name_utils/human_name_utils.rb'


RSpec.describe "HumanNameUtils" do
  def e(n1, n2)
    expect(HumanNameUtils.fuzzy_equal?(n1, n2)).to eq(true), "expected #{n1} === #{n2}"
    expect(HumanNameUtils.fuzzy_equal?(n2, n1)).to eq(true), "expected #{n1} === #{n2}"
  end

  def ne(n1, n2)
    expect(HumanNameUtils.fuzzy_equal?(n1, n2)).to eq(false), "expected #{n1} !== #{n2}"
    expect(HumanNameUtils.fuzzy_equal?(n2, n1)).to eq(false), "expected #{n1} !== #{n2}"
  end

  it "can cleanup names" do
    expect(HumanNameUtils.cleanup_name("Calvin Claus BSc")).to eq("Calvin Claus")
    expect(HumanNameUtils.cleanup_name("Karin Haberleithner, MSc, MBA")).to eq("Karin Haberleithner")
  end

  it "knows if two names are likely to be equal" do
    e("Calvin Claus BSc", "Calvin Claus")
    e("Claus Calvin BSc", "Calvin Claus")
    e("Calvin Claus BSc", "Claus Calvin")
    e("Shirin Badawi", "Shirin Badawi-Claus")
    e("Shirin Badawi ❤️", "Shirin Badawi-Claus")
    e("Hans-Christian K", "Hans-Christian Kern")
    e("Hans-Christian K.", "Hans-Christian Kern")
    e("Shirin  Badawi", "Shirin Badawi")
    e("Karl, Kern", "Karl Kern")
    e("Kern, Karl", "Karl Kern")
    e("Kern, Karl", "Kern Karl")
  end

  it "knows if tow name are likely not equal" do
    ne("Christian Claus", "Calvin Claus")
    ne("Julian Bauer", "Patrick Blaha")
    ne("Hans-Christian K.", "Kristof Kern")
    ne("Karl Kern", "Kristof K.")
    ne("Karl Kern", "Kristof K")
  end

  it "can deal with umlauts + co" do
    e("Peter Bäneton", "Peter Baeneton")
    e("Peter Baneton", "Peter Baneton")
    e("Peter Banèton", "Peter Baneton")
    e("Peter Schußter", "Peter Schusster")
    e("Karin Haberleithner, MSc, MBA", "Karin Haberleithner")
  end

  it "can clean and split name" do
    expect(HumanNameUtils.clean_and_split_name("Calvin Claus").to_h).to eq(first: "Calvin", last: "Claus")
    expect(HumanNameUtils.clean_and_split_name("BSc. Calvin Claus").to_h).to eq(first: "Calvin", last: "Claus")
    expect(HumanNameUtils.clean_and_split_name("BSc. Calvin Claus MSc.").to_h).to eq(first: "Calvin", last: "Claus")
    expect(HumanNameUtils.clean_and_split_name("BSc. Shirin Badawi-Claus MSc.").to_h).to eq(first: "Shirin", last: "Claus")
    expect(HumanNameUtils.clean_and_split_name("BSc. shirin badawi").to_h).to eq(first: "Shirin", last: "Badawi")
    expect(HumanNameUtils.clean_and_split_name("☛ Dipl.-Ing.(FH) Stefan Daschek").to_h).to eq(first: "Stefan", last: "Daschek")
    expect(HumanNameUtils.clean_and_split_name("☛ Ing(FH) Stefan Daschek").to_h).to eq(first: "Stefan", last: "Daschek")
    expect(HumanNameUtils.clean_and_split_name("☛ Dipl.-Ing.(FH (aber nur manchmal)) Stefan Daschek").to_h).to eq(first: "Stefan", last: "Daschek")
    expect(HumanNameUtils.clean_and_split_name("☛ Ing Stefan Daschek").to_h).to eq(first: "Stefan", last: "Daschek")
    expect(HumanNameUtils.clean_and_split_name("☛ Ing_ Stefan Daschek").to_h).to eq(first: "Stefan", last: "Daschek")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber Tcm.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber M.A.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber M.Sc.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber m.sc.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska_Huber m.sc.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber | m.sc.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber M.D.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber M.A.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber m.a.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber ma").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber md.").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber md").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Dr. Franziska Huber md").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("dr Franziska Huber md").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("dr-Franziska Huber md").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("DR-PHIL Franziska Huber md").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("dr. phil. Franziska Huber md").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska Huber (random title)").to_h).to eq(first: "Franziska", last: "Huber")
    expect(HumanNameUtils.clean_and_split_name("Franziska H. (random title)").to_h).to eq(first: "Franziska", last: "H.")
    expect(HumanNameUtils.clean_and_split_name("Franziska H (random title)").to_h).to eq(first: "Franziska", last: "H.")
    expect(HumanNameUtils.clean_and_split_name("Kirsten Waller, M.A.").to_h).to eq(first: "Kirsten", last: "Waller")
    expect(HumanNameUtils.clean_and_split_name("Kirsten Cfalla CFA").to_h).to eq(first: "Kirsten", last: "Cfalla")
    expect(HumanNameUtils.clean_and_split_name("Kirsten Cfalla cfa").to_h).to eq(first: "Kirsten", last: "Cfalla")
    expect(HumanNameUtils.clean_and_split_name("Kirsten Tcmina tcm").to_h).to eq(first: "Kirsten", last: "Tcmina")
    expect(HumanNameUtils.clean_and_split_name("Kirsten Tcmina TCM").to_h).to eq(first: "Kirsten", last: "Tcmina")
    expect(HumanNameUtils.clean_and_split_name("Kirsten Tcmina Tcm").to_h).to eq(first: "Kirsten", last: "Tcmina")

    expect(HumanNameUtils.clean_and_split_name("DI Marcel Nürnberg").to_h).to eq(first: "Marcel", last: "Nürnberg")
    expect(HumanNameUtils.clean_and_split_name("DI Dieter Nürnberg").to_h).to eq(first: "Dieter", last: "Nürnberg")
    expect(HumanNameUtils.clean_and_split_name("Dieter Nürnberg").to_h).to eq(first: "Dieter", last: "Nürnberg")

    expect(HumanNameUtils.clean_and_split_name("Alexander-Peter Nürnberg").to_h).to eq(first: "Alexander", last: "Nürnberg")
    expect(HumanNameUtils.clean_and_split_name("Alexander-Peter Nürnberg-Berger").to_h).to eq(first: "Alexander", last: "Berger")
    expect(HumanNameUtils.clean_and_split_name("Josef-Alexander Haselberger").to_h).to eq(first: "Josef", last: "Haselberger")
    expect(HumanNameUtils.clean_and_split_name("Carine Pottier - Assoc CIPD").to_h).to eq(first: "Carine", last: "Pottier")
    expect(HumanNameUtils.clean_and_split_name("BSC - Carine Pottier - Assoc CIPD").to_h).to eq(first: "Carine", last: "Pottier")
    expect(HumanNameUtils.clean_and_split_name("Keiron Molyneux BA(Hons) FdSc ACMI LCGI").to_h).to eq(first: "Keiron", last: "Molyneux")
    expect(HumanNameUtils.clean_and_split_name("Peter Rees CFCIPD/ MSC").to_h).to eq(first: "Peter", last: "Rees")
    expect(HumanNameUtils.clean_and_split_name("Parveen Baba MCIPD PMP®").to_h).to eq(first: "Parveen", last: "Baba")
    expect(HumanNameUtils.clean_and_split_name("Kate Burrell FCIPD").to_h).to eq(first: "Kate", last: "Burrell")
    expect(HumanNameUtils.clean_and_split_name("Andreas Wende FRICS").to_h).to eq(first: "Andreas", last: "Wende")
  end
end
