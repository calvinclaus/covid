# README

# Preventing Headless Browser Detection Learnings

Chrome Buildpack:
I never finished writng the buildpack for the lower chrome version that does not have navigator.something defined that can be used to detect it. However the user agent string in the CapybaraHeadlessBrowser class is already set to something useful that does not have "Headless" in its string.
If I had to get the buildpack working I would run this buildpack:
https://github.com/heroku/heroku-buildpack-google-chrome/blob/master/bin/compile
Eitehr by also including it as a pack or copying all its source. And then at the end
tack on the installation of https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/499089/ this chromium binary. Find out how to expose the binary location as a ENV variable. Probably get Stefan to help for a couple of hours though.
Link to my non finished chromium buildpack: https://github.com/calvinclaus/chromium-buildpack.
NOTE: This needs the heroku-buildpack-google-chrome to run before to install all these need packages X11 etc.
I never got the binary working with CapybaraHeadlessChrome code it would say it couldn't find the bianry at the location. Maybe because it never got properly installed?

The chromium to use locally: https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Mac/499098 that doesnt have the navgator.blabla set.


Some blog about ways to detect on client side:
https://antoinevastel.com/bot%20detection/2018/01/17/detect-chrome-headless-v2.html
Counter blogs:
https://intoli.com/blog/making-chrome-headless-undetectable/
https://intoli.com/blog/not-possible-to-block-chrome-headless/


Find Chrome Version Branch Base Position:
https://stackoverflow.com/questions/54927496/how-to-download-older-versions-of-chrome-from-a-google-official-site?rq=1
https://omahaproxy.appspot.com/
Look for Chrome Version with Branch Position:
prefix=Mac
prefix=Linux_x64
https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/499089/


Get sent headers echoed:
http://scooterlabs.com/echo.json

Compare JSON
https://jsoncompare.com/#!/diff/fullscreen/

Chrome Browser/Driver Compatibility:
https://stackoverflow.com/questions/41133391/which-chromedriver-version-is-compatible-with-which-chrome-browser-version/49618567#49618567


# Duplicate Prospects

There hasn't been set a unique constraint on Prospect::vmid, and there seems to have been (or still exist, but dont think so) a secenario where search imports duplicated prospects.
This has only been a problem with company_id 38 in the wild right now, as it was sending already contacted prospects to the agent.

This snippet can be used to understand how many duplicate vmids exist for each company.
A lot of them seem to exist for Julian Wiehl - but it doesn't seem to pose a practical problem as of now so hasn't been solved.
//duplicates over all companies
Company.all.map { |company| { id: company. id, dups: company.prospects.where('EXISTS (SELECT * FROM prospects p2 where p2.id != "prospects".id AND p2.vmid = "prospects".vmid AND "prospects"."company_id" = p2.company_id)').order(:vmid).size } }.select { |c| c[:dups] > 0 }

Here are some useful snippets to get rid of duplicates created this way in the future:
//attempt to remove duplicates by reimporting searches
company_id = 38
Company.find(company_id).prospects.where('EXISTS (SELECT * FROM prospects p2 where p2.id != "prospects".id AND p2.vmid = "prospects".vmid AND "prospects"."company_id" = p2.company_id)').order(:vmid).size
Company.find(company_id).prospects.unused_or_unassigned.destroy_all
Company.find(company_id).searches.each { |s| s.sync_prospects_from_csv }
Company.find(company_id).distribute_prospects_to_campaigns_idempotently

Company.find(company_id).prospects.where('EXISTS (SELECT * FROM prospects p2 where p2.id != "prospects".id AND p2.vmid = "prospects".vmid AND "prospects"."company_id" = p2.company_id)').order(:vmid).unused_or_unassigned.size



# Buildpacks
Chrome buildpacks removed weil es die deploy Zeit nach oben schraubt und es eh nicht verwendet wird.
1. heroku/ruby
2. https://github.com/heroku/heroku-buildpack-google-chrome
3. https://github.com/heroku/heroku-buildpack-chromedriver.git

Added jemalloc buildpack
https://github.com/gaffneyc/heroku-buildpack-jemalloc
heroku buildpacks:add --index 1 https://github.com/gaffneyc/heroku-buildpack-jemalloc.git
heroku config:set JEMALLOC_ENABLED=true


# Links
Dynamic sorting animation:
https://github.com/FormidableLabs/react-shuffle

Annahmerate/Antwortrate über Zeit

3. Strich auf der Progress bar "1. Progressbar"

Immer beidees % und absolute

annahmerate. 1. nachricht reagiert, 2. nachricht reagiert

## Tests
If you're writing acceptance tests with Capybara, use the feature / scenario syntax, if not use describe / it syntax.

## Discussion of dashboard

React vs Rails. Ugh. Just do it in react and shut up. Done.

Should we use a bootstrap template? Not really....maybe? How compatible with react? Probably easy if they use chart js.

At the moment let's focus on what goes into the dashbaord.

- ZEROK work from end users.
    -> If there is just one campaign open that one straight away.

- Key stakeholders:
  - > Sales/Recruiter/LinkedIn Account holder
  - > Renewal decision maker

Wie viele Leute wurden bis jetzt kontaktiert?
Wie viele Leute haben geantwortet?

Nach message Änderung: wie hat sich die Antwortrate verändert? <- reicht eigentlich ein log eintrag für eine Message Änderung.

Wie viele Leute haben positiv geantwortet?
Mit wie vielen Leuten bekma ich einen call/präsentation/next_step_x
Wie vile Leute haben abgeschlossen?

Display the value of the app to the entire organization. The dashbaord needs to be good enough to show at a board meeting.
Provides genuine, and ideally daily, value to the key stakeholders.  Whoever logs into your app every day should get genuine value from the dashboard, ideally more from it than any other part of the app.  Challenge yourself here.  It needs to be much more than just a random tab or a potential view.  It should be the #1 place your key managers and stakeholders go.
Clearly displays the value of the app to the entire organization — including the CEO.  This is the third part.  The dashboard should show ROI to the whole company so clearly, that even the CEO gets value from it.  Even if she has never even logged into the app.  Think of a dashboard good enough to show at a board meeting.  Make sure your core dashboard does that.




## Discussion of architecture

Need to find a compromise between architecture changes down the line
and overengineering today.

Should each campaign get a single search url, or should a campaign have a bunch of searches?
What would we like to have?
A possinility to configure a client to run for X amount of time split into N time period periods P_1...N.
Could this be solved by configuring mulitple campaigns and then setting when each should run? Or set a trigger.
Run once the other one finished.

In general though multiple searches may be part of the same campaign. i.e. look for HR in AT, GER etc. that we're adressing
with the same messages. Genereally we need multiple searchs to be handled within a campaign.
A campaign should be able to split a search into 1000s on its own. This might be premature optimization ATM.

first month should be 750ppl from SEARCH A and 750ppl from SEARCH B, tell me the duration the campaign can run
2 monthts 3000 people from search A, blacklist companies csv A, before start allow customers to delete prospects
3 months, get as many as necessary from SEARCH A
Get as many as possible from SEARCH A, then as many as possible form SEARCH B, tell me the duration the campaign can run
A DSL to describe campagins? Would have to hardcode each possibility. Nah..
The UI should feel like you're planning out the campaign. Not handling searches, cookies and csvs.
It should be declarative not imperative.

Okay...this can go a thousand ways. We need to do this iteratively. I want to be able to iterate fast into all possible
directions that I can think of now. So let's have a solid architecture that would allow all the things above to be implemented
withoug chaning the data structures a lot. Addings new ones is fine.

Campaign:
  - name
  ( - target_audience_description; notes are sufficient)
  - notes
  - log
  - phantombuster_agent_id
  - timestamps
  - ref: linked_in_account

We have the following steps in a campaign
  - search [LIAccount Necessary]
  - blacklist/filter
  - convert sales nav urls [LIAccount Necessary]
  - invite [LIAccount Necessary] -
  - followup [LIAccount Necessary]

Ordered by how much work it releases from me:
Setup Campaign
See stats
Update LinkedIn Cookie.
Update Message.
Export lists

- We don't really know yet if the sales-nav conversion makes a difference in the stability of an account. ATM we think it doesn't. But implementing this on our end would be the best solution but also require quite a decent scheduling setup. log our report etc. 2 days work for sure.

We will also want to handle campaigns within the existing network.

And we should be able to run export tasks: accepted but not responded export for example.

This doesn't seem particlarly relevant right now: We could build a system that allows us to chain tasks on csvs together in some way? maybe not the right abstraction though.


LinkedInAccount: -> splitting has the advantage of being able to update the cookie in one place if it is used in more than one scenario. also allows choosing of an account for task. need!
  - name
  - session_cookie
  - timestamps

Possible Prospects Model
saves individual contacted, times,  responsed?, messages, what query originally discovered the person.
We could theoretically fill

CampaignStatistics
what to save here? .. let's try a hard copy of pbs csv file for now..


This README would normally document whatever steps are necessary to get the
application up and running.



Okay so first iteration:

Campaign:
  - name
  - notes
  - phantombuster_agent_id
  - timestamps

Setup, search and changes stays with pb. Then iterate from there.


Log statements that might be useful for split duplicate assignments in prospect_pool.rb

    #puts "invocation #{name}. campaigns in pool: #{campaigns.pluck(:name)}"
    #puts "all prospects in pool: #{prospects.pluck(:name)}, used: #{prospects.used.pluck(:name)}"
    #puts "all prospects in company: #{company.prospects.pluck(:name)}, used: #{company.prospects.used.pluck(:name)}"
    #puts prospects.used.to_sql
    # "Prospect::used" uses .joins(:prospect_campaign_associations), which joins on both the campaigns and prospects of the existing query that is generated by rails for propsects() in this class by the has_many() calls above.
    # This has the comfortable side effect of only retrieving prospects that are part of at least one campaign of this prospect pool, that have been used by at least one campaign of this prospect pool but ignoring any usage of a prospect by a campaign not part of this prospect pool
    prospects.used.each do |p|
      #puts "Prospect has been used #{p.name}. Prospect association with: #{p.prospect_campaign_associations.map { |a| a.campaign.name }}. Unused prospect campaign association #{p.prospect_campaign_associations.unused.map { |a| a.campaign.name }}"
      p.prospect_campaign_associations.where(campaign: campaigns).unused.delete_all
    end




Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
