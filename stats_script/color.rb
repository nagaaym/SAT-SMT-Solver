#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'pry'

load "stats_script/base.rb"

def color1(name,threads)
  db = Database::new

  algos = ["dpll","wl"]
  heuristics = ["dlis","jewa","dlcs"]
    
  def boucle(algos,heuristics,&block)
    (1..1000).each do |n|
      (0..5).each do |x|
        timeout = {}
        (1..(n/10)).each do |k|
          2.times do 
            p = ProblemColor::new(n,x/5.0,10*k)
            puts p
            proc = p.gen
            algos.each do |algo|
              heuristics.each do |h|
                report = Report::new
                begin
                  raise Timeout::Error if timeout[algo+h]
                  entry,result = proc.call(algo,h,60)
                  report << result
                  yield(entry,report) if result
                rescue Timeout::Error
                  puts "Timeout : #{p}, #{algo}, #{h}"
                  timeout[algo+h] = true
                end 
              end
            end
          end
        end
      end
    end
  end

  threads.times do 
    Thread::new do
      boucle(algos,heuristics) { |entry,report| db.record(entry,report) }
    end
  end

  while Thread::list.length != 1 do
    system "date -R"
    puts "Saving"
    db.save name
    puts "Done"
    sleep 60
  end

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end

def analyze name
  db = Database::new name
  
  names = {:title => "Temps d'execution de color (n=10)", :xlabel=>"p", :ylabel => "Temps (s)"}

  l = select_data({:vertices => 10, :heuristic => Heuristics - ["jewa"]}) { |p, r| [p[:algo]+"+"+p[:heuristic],p[:p],r["Time (s)"]] }

  db.to_gnuplot l,"stats_script/skel.p",names
  db
end

pry
