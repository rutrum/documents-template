_default: watch

# Compile all documents that are out of date.
all:
    #!/usr/bin/env sh
    for file in $(fd . src/ -e md --exclude "_*"); do \
        ext=$(just _get_ext $file)
        output=$(pathmut first -s target $file | pathmut ext -s $ext); \
        just _checkexec $file $output; \
    done

# Individually build a single file.
compile INPUT:
    #!/usr/bin/env sh
    ext=$(just _get_ext {{INPUT}})
    just _pandoc {{INPUT}} $(pathmut first -s target {{INPUT}} | pathmut ext -s $ext)

_checkexec INPUT OUTPUT:
    @checkexec {{OUTPUT}} {{INPUT}} $(just _options {{INPUT}} | xargs -I {} echo -n "{} ") -- just _pandoc {{INPUT}} {{OUTPUT}}

_pandoc INPUT OUTPUT:
    #!/usr/bin/env sh
    mkdir -p $(pathmut parent {{OUTPUT}} )
    pandoc --log=log.txt \
        $(just _defaults_args {{INPUT}}) \
        {{INPUT}} \
        -o {{OUTPUT}}
    echo "\e[1m{{INPUT}} -> {{OUTPUT}}"

# Watch markdown documents for changes and recompile.
watch:
    watchexec -w src -- just all

# Clean the output directory.
clean:
    rm -r target/*

# Print files.
tree:
    tree -I target --dirsfirst

# Print list of spelling errors in a file.
spell-list FILE:
    cat {{FILE}} | aspell list \
        --mode="tex" \
        --add-filter="markdown" \
        --personal="./dictionary/word_list.pws"

# Interactively fix spelling errors in a file.
spell FILE:
    aspell check {{FILE}} \
        --mode="tex" \
        --add-filter="markdown" \
        --personal="./dictionary/word_list.pws"

lint FILE:
    proselint --config proselint.json {{FILE}}

# print all the options.yml in ancestors of FILE
_options FILE:
    #!/usr/bin/env sh
    P={{FILE}}
    P=$(pathmut parent $P)
    while [[ -n "$P" ]]; do
        option="$P/defaults.yml"
        if [[ -e $option ]]; then
            echo $option
        fi
        P=$(pathmut parent $P)
    done

_defaults_args FILE:
    #!/usr/bin/env sh
    just _options {{FILE}} | tac | xargs -I {} echo -n "--defaults={} "

# Determines extension based on defaults.yml 'to' format
_get_ext FILE:
    #!/usr/bin/env sh
    to=$(just _options {{FILE}} | tac | xargs echo -n \
        | xargs yq ea '. as $item ireduce ({}; . * $item) | .to')
    case $to in
        revealjs) echo html ;;
        latex) echo pdf ;;
    esac
