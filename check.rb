while true
  sleep 1
  @html_time = File.open("index.html"){ |io| io.mtime }
  @haml_time = File.open("template.haml"){ |io| io.mtime }

  if @html_time < @haml_time
    `haml template.haml > index.html`
  end
end
