# RubySippers

SIPp is a great tool for testing the SIP protocol. However, it can be difficult and error-prone to construct and maintain complex scenarios.

RubySIPPers is a framework built on top of SIPp which allows you to concisely express the real scenario you are trying to test, and will coordinate multiple endpoints.

look at example/test_case.rb for how it can be used

before you start:
- copy the code to your box and require ruby_sippers.rb from your testcase
- create a directory ./output in the directory you are running the test from
- create a directory ~/sipp_scenarios on the target host
- make sure your user has ssh keys set up between the box initiating the test and the target host
- have the compiled SIPp executable on your target host under /site/test-tools/bin

depends on:
- test/unit
- nokogiri
- open-uri
- csv
- net/ssh

known issues:
- might not be able to initiate calls with PCAP audio (due to pthread_setschedparam calls being restricted to root on some systems)

plan for future releases:
- gemify
- turn into server/client appication
- fix problem with initiating calls with audio

please contact me for suggestions and if you come across a bug

Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
