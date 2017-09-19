#!/usr/bin/env ruby

require 'rubygems'
require 'jira-ruby'

class Issue
  def initialize(client, issue_key)
    @issue = client.Issue.find(issue_key)
  end

  def mark_in_progress
    if (@issue.status.name == 'Backlog' || @issue.status.name == 'Selected for Development')
      @issue.transitions.build.save!('transition': {'id': '31'})
    end
  end

  def add_comment(comment)
    @issue.comments.build.save!('body': comment)
  end

  def close(comment)
    add_comment comment
    @issue.transitions.build.save!('transition': {'id': '41'})
  end
end


options = {
  :username     => ENV['JIRA_USER']
  :password     => ENV['JIRA_PASSWORD']
  :site         => ENV['JIRA_SITE']
  :context_path => '',
  :auth_type    => :basic,
  :http_debug   => false
}

client = JIRA::Client.new(options)

issue_key = ARGV[0] || 'PROJ1-1'
command = ARGV[1] || 'comment'
comment = ARGV[2] || 'There should have been a more useful comment here.'

begin
  issue = Issue.new(client, issue_key)
  issue.mark_in_progress

  case command
  when 'comment'
    issue.add_comment comment
    puts "Added comment to issue #{issue_key}: #{comment}"
  when 'close'
    issue.close comment
    puts "Closed issue #{issue_key}: #{comment}"
  end

rescue => e
  STDERR.puts "Failed to update Jira for issue: #{issue_key} with comment:\n----\n#{comment}\n---\nError: #{e.message}"
end
