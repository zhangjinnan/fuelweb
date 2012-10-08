require 'open-uri'

def with(value)
  yield(value)
end

# copy_files 'articles/*.gif', 'articles', :articles
def copy_files(srcGlob, targetDir, taskSymbol)
  mkdir_p targetDir
  FileList[srcGlob].each do |f|
    target = File.join targetDir, File.basename(f)
    file target => [f] do |t|
      cp f, target
    end
    task taskSymbol => target
  end
end

def download_from_url(url, target_file, task_symbol)
  file target_file do
    directory File.dirname(target_file)
    puts "Downloading from url: #{url}"
    open("#{target_file}.tmp", 'wb') do |file|
      file << open(url).read
    end
    mv "#{target_file}.tmp", target_file
  end
  task task_symbol => target_file
end
