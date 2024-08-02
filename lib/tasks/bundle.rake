namespace :bundle do
  desc "Audit bundle for any known vulnerabilities"
  task :audit do
    unless system "bundle-audit check --update --ignore GHSA-r95h-9x8f-r3f7"
      exit 1
    end
  end
end
