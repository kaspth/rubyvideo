speakers = YAML.load_file("#{Rails.root}/data/speakers.yml")
organisations = YAML.load_file("#{Rails.root}/data/organisations.yml")
videos_to_ignore = YAML.load_file("#{Rails.root}/data/videos_to_ignore.yml")

# create speakers
speakers.each do |speaker|
  speaker = Speaker.find_or_create_by!(name: speaker["name"]) do |spk|
    spk.twitter = speaker["twitter"]
    spk.github = speaker["github"]
    spk.website = speaker["website"]
    spk.bio = speaker["bio"]
  end
end

MeiliSearch::Rails.deactivate! do
  organisations.each do |organisation|
    organisation = Organisation.find_or_create_by!(slug: organisation["slug"]) do |org|
      org.name = organisation["name"]
      org.website = organisation["website"]
      # org.twitter = organisation["twitter"]
      org.youtube_channel_name = organisation["youtube_channel_name"]
      org.kind = organisation["kind"]
      org.frequency = organisation["frequency"]
      org.youtube_channel_id = organisation["youtube_channel_id"]
      org.slug = organisation["slug"]
      # org.language = organisation["language"]
    end

    events = YAML.load_file("#{Rails.root}/data/#{organisation.slug}/playlists.yml")

    events.each do |event_data|
      event = Event.find_by(slug: event_data["slug"])
      next if event

      event = Event.create!(name: event_data["title"], date: event_data["published_at"], organisation: organisation)

      event.update!(slug: event_data["slug"])

      puts event.slug unless Rails.env.test?
      talks = YAML.load_file("#{Rails.root}/data/#{organisation.slug}/#{event.slug}/videos.yml")

      talks.each do |talk_data|
        next if talk_data["title"].blank? || videos_to_ignore.include?(talk_data["video_id"])

        talk = Talk.find_or_create_by!(title: talk_data["title"], event: event) do |tlk|
          tlk.description = talk_data["description"]
          tlk.video_id = talk_data["video_id"]
          tlk.video_provider = :youtube
          tlk.language = talk_data["language"]
          tlk.thumbnail_xs = talk_data["thumbnail_xs"] || ""
          tlk.thumbnail_sm = talk_data["thumbnail_sm"] || ""
          tlk.thumbnail_md = talk_data["thumbnail_md"] || ""
          tlk.thumbnail_lg = talk_data["thumbnail_lg"] || ""
          tlk.thumbnail_xl = talk_data["thumbnail_xl"] || ""

          year = talk_data["year"].presence || event_data["year"]
          tlk.date = talk_data["date"] || talk_data["published_at"] || Date.parse("#{year}-01-01")

          slug = talk_data["title"].parameterize

          if Talk.exists?(slug: slug)
            slug += event_data["title"].parameterize
          end

          tlk.slug = slug
        end

        talk_data["speakers"]&.each do |speaker_name|
          next if speaker_name.blank?

          speaker = Speaker.find_by(slug: speaker_name.parameterize) || Speaker.find_or_create_by(name: speaker_name.strip)
          SpeakerTalk.create(speaker: speaker, talk: talk) if speaker
        end
      rescue ActiveRecord::RecordInvalid => e
        puts "#{talk_data["title"]} is duplicated #{e.message}"
      end
    end
  end
end

# reindex all talk in MeiliSearch
Talk.reindex! unless Rails.env.test?

topics = [
  "A/B Testing",
  "Accessibility (a11y)",
  "ActionCable",
  "ActionMailbox",
  "ActionMailer",
  "ActionPack",
  "ActionText",
  "ActionView",
  "ActiveJob",
  "ActiveModel",
  "ActiveRecord",
  "ActiveStorage",
  "ActiveSupport",
  "Algorithms",
  "Android",
  "Angular.js",
  "Arel",
  "Artificial Intelligence (AI)",
  "Assembly",
  "Authentication",
  "Authorization",
  "Automation",
  "Awards",
  "Background jobs",
  "Behavior-Driven Development (BDD)",
  "Blogging",
  "Bootstrapping",
  "Bundler",
  "Business Logic",
  "Business",
  "Caching",
  "Capybara",
  "Career Development",
  "CI/CD",
  "Client-Side Rendering",
  "Code Golfing",
  "Code Organization",
  "Code Quality",
  "Command Line Interface (CLI)",
  "Communication",
  "Communication",
  "Community",
  "Compiling",
  "Components",
  "Computer Vision",
  "Concurrency",
  "Containers",
  "Content Management System (CMS)",
  "Content Management",
  "Continuous Integration (CI)",
  "Contributing",
  "CRuby",
  "Crystal",
  "CSS",
  "Data Analysis",
  "Data Integrity",
  "Data Migrations",
  "Data Persistence",
  "Data Processing",
  "Database Sharding",
  "Databases",
  "Debugging",
  "Dependency Management",
  "Deployment",
  "Design Patterns",
  "Developer Expierience (DX)",
  "Developer Tooling",
  "Developer Tools",
  "Developer Workflows",
  "DevOps",
  "Distributed Systems",
  "Diversity & Inclusion",
  "Docker",
  "Documentation Tools",
  "Documentation",
  "Domain Driven Design",
  "Domain Specific Language (DSL)",
  "dry-rb",
  "Duck Typing",
  "E-Commerce",
  "Early-Career Devlopers",
  "Editor",
  "Elm",
  "Encoding",
  "Encryption",
  "Engineering Culture",
  "Error Handling",
  "Ethics",
  "Event Sourcing",
  "Fibers",
  "Flaky Tests",
  "Frontend",
  "Functional Programming",
  "Game Shows",
  "Games",
  "Geocoding",
  "git",
  "Go",
  "Graphics",
  "GraphQL",
  "gRPC",
  "Hacking",
  "Hanami",
  "Hotwire",
  "HTML",
  "HTTP API",
  "Hybrid Apps",
  "Indie Developer",
  "Inspiration",
  "Integrated Development Environment (IDE)",
  "Integration Test",
  "Internals",
  "Internationalization (I18n)",
  "Interview",
  "iOS",
  "Java Virtual Machine (JVM)",
  "JavaScript",
  "Job Interviewing",
  "JRuby",
  "JSON Web Tokens (JWT)",
  "Just-In-Time (JIT)",
  "Kafka",
  "Keynote",
  "Language Server Protocol (LSP)",
  "Large Language Models (LLM)",
  "Leadership",
  "Legacy Applications",
  "Licensing",
  "Lightning Talks",
  "Linters",
  "Live Coding",
  "Localization (L10N)",
  "Logging",
  "Machine Learning",
  "Majestic Monolith",
  "Markup",
  "Math",
  "Memory Managment",
  "Mental Health",
  "Mentorship",
  "MFA/2FA",
  "Microcontroller",
  "Microservices",
  "Minimum Viable Product (MVP)",
  "Minitest",
  "MJIT",
  "Mocking",
  "Model-View-Controller (MVC)",
  "Monitoring",
  "Monolith",
  "mruby",
  "Multitenancy",
  "Music",
  "MySQL",
  "Naming",
  "Native Apps",
  "Native Extensions",
  "Networking",
  "Object-Oriented Programming (OOP)",
  "Object-Relational Mapper (ORM)",
  "Observability",
  "Offline-First",
  "Open Source",
  "Organizational Skills",
  "Pair Programming",
  "Panel Discussion",
  "Parallelism",
  "Parsing",
  "Passwords",
  "People Skills",
  "Performance",
  "Personal Development",
  "Phlex",
  "Podcasts",
  "PostgreSQL",
  "Pricing",
  "Privacy",
  "Productivity",
  "Profiling",
  "Progressive Web Apps (PWA)",
  "Project Planning",
  "Quality Assurance (QA)",
  "Questions and Anwsers (Q&A)",
  "Rack",
  "Ractors",
  "Rails at Scale",
  "Rails Engine",
  "Rails Plugins",
  "Rails Upgrades",
  "Railties",
  "React.js",
  "Real-Time Applications",
  "Refactoring",
  "Regex",
  "Remote Work",
  "Reporting",
  "REST API",
  "REST",
  "Rich Text Editor",
  "RJIT",
  "Robot",
  "RPC",
  "RSpec",
  "Ruby Implementations",
  "Ruby on Rails",
  "Ruby VM",
  "Rubygems",
  "Rust",
  "Scaling",
  "Science",
  "Security Vulnerability",
  "Security",
  "Selenium",
  "Server-side Rendering",
  "Servers",
  "Service Objects",
  "Shoes.rb",
  "Sidekiq",
  "Sinatra",
  "Single Page Applications (SPA)",
  "Software Architecture",
  "Sonic Pi",
  "Sorbet",
  "SQLite",
  "Startups",
  "Static Typing",
  "Stimulus.js",
  "Structured Query Language (SQL)",
  "Success Stories",
  "Swift",
  "Syntax",
  "System Programming",
  "System Test",
  "Tailwind CSS",
  "Teaching",
  "Team Building",
  "Teams",
  "Teamwork",
  "Templating",
  "Template Engine",
  "Test Coverage",
  "Test Framework",
  "Test-Driven Development",
  "Testing",
  "Threads",
  "Timezones",
  "Tips & Tricks",
  "Trailblazer",
  "Translation",
  "Transpilation",
  "TruffleRuby",
  "Turbo Native",
  "Turbo",
  "Type Checking",
  "Types",
  "Typing",
  "UI Design",
  "Unit Test",
  "Usability",
  "User Interface (UI)",
  "Version Control",
  "ViewComponent",
  "Views",
  "Virtual Machine",
  "Vue.js",
  "Web Components",
  "Web Server",
  "Websockets",
  "why the lucky stiff",
  "Workshop",
  "Writing",
  "YARV (Yet Another Ruby VM)",
  "YJIT (Yet Another Ruby JIT)"
]

# create topics
Topic.create_from_list(topics, status: :approved)
