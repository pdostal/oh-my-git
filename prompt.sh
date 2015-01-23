PSORG=$PS1;

if [ -n "${BASH_VERSION}" ]; then
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    : ${omg_ungit_prompt:=$PS1}
    : ${omg_second_line:='\w • '}

    : ${omg_is_a_git_repo_symbol:=''} #    
    : ${omg_adds_symbol:=''}        #                ?     
    : ${omg_dels_symbol:=''} # 
    : ${omg_sets_symbol:=''} # 
    : ${omg_action_symbol:=''}
    : ${omg_ready_to_commit_symbol:=''}            #   →
    : ${omg_is_on_a_tag_symbol:=''}                #   
    : ${omg_detached_symbol:=''}
    : ${omg_can_fast_forward_symbol:=''}
    : ${omg_has_diverged_symbol:=''}               #   
    : ${omg_not_tracked_branch_symbol:=''}
    : ${omg_rebase_tracking_branch_symbol:=''}     #   
    : ${omg_merge_tracking_branch_symbol:=''}      #  
    : ${omg_should_push_symbol:=''}                #    
    : ${omg_stashes_symbol:=''}

    PROMPT='$(build_prompt)'
    RPROMPT='%{$reset_color%}%T %{$fg_bold[white]%} %n@%m%{$reset_color%}'

    function enrich_append {
        local flag=$1
        local symbol=$2
        local color=$3
        if [[ $flag == true ]]; then echo -n "${color} ${symbol} "; fi
    }

    function custom_build_prompt {
        local enabled=${1}
        local current_commit_hash=${2}
        local is_a_git_repo=${3}
        local current_branch=$4
        local detached=${5}
        local just_init=${6}
        local has_upstream=${7}
        local number_of_untracked_sets=${8}
        local number_of_cached_sets=${9}
        local number_of_cached_adds=${10}
        local number_of_untracked_dels=${11}
        local number_of_cached_dels=${12}
        local number_of_untracked_adds=${13}
        local ready_to_commit=${14}
        local tag_at_current_commit=${15}
        local is_on_a_tag=${16}
        local has_upstream=${17}
        local commits_ahead=${18}
        local commits_behind=${19}
        local has_diverged=${20}
        local should_push=${21}
        local will_rebase=${22}
        local has_stashes=${23}
        local action=${24}

        local prompt=""
        local original_prompt=$PS1

        # foreground
        local black='\e[0;30m'
        local red='\e[0;31m'
        local green='\e[0;32m'
        local yellow='\e[0;33m'
        local blue='\e[0;34m'
        local purple='\e[0;35m'
        local cyan='\e[0;36m'
        local white='\e[0;37m'

        #background
        local background_black='\e[40m'
        local background_red='\e[41m'
        local background_green='\e[42m'
        local background_yellow='\e[43m'
        local background_blue='\e[44m'
        local background_purple='\e[45m'
        local background_cyan='\e[46m'
        local background_white='\e[47m'

        local reset='\e[0m'     # Text Reset]'

        local theme_filesystem_arrow_color=$white
        local theme_filesystem_front_color=$black
        local theme_filesystem_stash_color=$yellow
        local theme_filesystem_untracked_color=$cyan
        local theme_filesystem_cached_color=$green
        local theme_filesystem_next_color=$red
        local theme_filesystem_back_color=$background_white

        local theme_action_arrow_color=$red
        local theme_action_front_color=$white
        local theme_action_back_color=$background_red

        local theme_branch_arrow_color=$green
        local theme_branch_front_color=$black
        local theme_branch_back_color=$background_green

        local theme_tag_arrow_color=$yellow
        local theme_tag_front_color=$black
        local theme_tag_back_color=$background_yellow

        if [[ $is_a_git_repo == true ]]; then
            local arrow_color=$theme_filesystem_arrow_color
            local front_color=$theme_filesystem_front_color
            local back_color=$theme_filesystem_back_color

            # on filesystem
            prompt="${front_color}${back_color} $omg_is_a_git_repo_symbol "

            if [[ $number_of_stashes -gt 0 ]]; then prompt+=$(enrich_append true "${omg_stashes_symbol} ${number_of_stashes}" "${theme_filesystem_stash_color}${back_color}"); fi

            if [[ $number_of_untracked_sets -gt 0 ]]; then prompt+=$(enrich_append true "${omg_sets_symbol} ${number_of_untracked_sets}" "${theme_filesystem_untracked_color}${back_color}"); fi
            if [[ $number_of_untracked_dels -gt 0 ]]; then prompt+=$(enrich_append true "${omg_dels_symbol} ${number_of_untracked_dels}" "${theme_filesystem_untracked_color}${back_color}"); fi
            if [[ $number_of_untracked_adds -gt 0 ]]; then prompt+=$(enrich_append true "${omg_adds_symbol} ${number_of_untracked_adds}" "${theme_filesystem_untracked_color}${back_color}"); fi
            if [[ $number_of_cached_sets -gt 0 ]]; then prompt+=$(enrich_append true "${omg_sets_symbol} ${number_of_cached_sets}" "${theme_filesystem_cached_color}${back_color}"); fi
            if [[ $number_of_cached_dels -gt 0 ]]; then prompt+=$(enrich_append true "${omg_dels_symbol} ${number_of_cached_dels}" "${theme_filesystem_cached_color}${back_color}"); fi
            if [[ $number_of_cached_adds -gt 0 ]]; then prompt+=$(enrich_append true "${omg_adds_symbol} ${number_of_cached_adds}" "${theme_filesystem_cached_color}${back_color}"); fi

            # next operation
            prompt+=$(enrich_append $ready_to_commit $omg_ready_to_commit_symbol "${theme_filesystem_next_color}${back_color}")

            # Actions
            local action_arrow_color=$theme_action_arrow_color # do not override $arrow_color
            local front_color=$theme_action_front_color
            local back_color=$theme_action_back_color
            action_prompt=""
            if [[ $detached == false && $has_upstream == true ]]; then
                if [[ $has_diverged == true ]]; then
                    action_prompt+=$(enrich_append true "${omg_has_diverged_symbol} ${commits_behind}±${commits_ahead}" ${front_color}${back_color})
                else
                    if [[ $commits_behind -gt 0 ]]; then
                        action_prompt+=$(enrich_append true "${omg_can_fast_forward_symbol} ${commits_behind}" ${front_color}${back_color})
                    fi
                    if [[ $commits_ahead -gt 0 ]]; then
                        action_prompt+=$(enrich_append true "${omg_should_push_symbol}  ${commits_ahead}" ${front_color}${back_color})
                    fi
                fi

                # Display remote branche
                if [ -n "$action_prompt" ]; then
                    if [[ $detached == true ]]; then
                        local branch_symbol="${omg_detached_symbol}"
                    else
                        if [[ $has_upstream == false ]]; then
                            local branch_symbol=$omg_not_tracked_branch_symbol
                        else
                            if [[ $will_rebase == true ]]; then
                                local branch_symbol=$omg_rebase_tracking_branch_symbol
                            else
                                local branch_symbol=$omg_merge_tracking_branch_symbol
                            fi
                        fi
                    fi
                    action_prompt+=$(enrich_append true "$branch_symbol ${upstream//\/$current_branch/}" "${front_color}${back_color}")
                fi
            fi
            if [ -n "$action" ]; then
                action_prompt+=$(enrich_append true "${omg_action_symbol} ${action}" ${front_color}${back_color})
            fi

            if [ -n "$action_prompt" ]; then
                prompt+="${arrow_color}${back_color}"
                prompt+="$action_prompt"

                local arrow_color=$action_arrow_color
            fi

            # branches
            local front_color=$theme_branch_front_color
            local back_color=$theme_branch_back_color
            prompt+="${arrow_color}${theme_branch_back_color}"
            local arrow_color=$theme_branch_arrow_color
            if [[ $detached == true ]]; then
                local branch_name="${current_commit_hash:0:7}"
            else
                local branch_name=$current_branch
            fi
            prompt+=$(enrich_append true "${branch_name}" "${front_color}${back_color}")

            # tag
            if [[ $is_on_a_tag == true ]]; then
                local front_color=$theme_tag_front_color
                local back_color=$theme_tag_back_color
                prompt+="${arrow_color}${back_color}"
                local arrow_color=$theme_tag_arrow_color
                prompt+=$(enrich_append true "${omg_is_on_a_tag_symbol} ${tag_at_current_commit}" "${front_color}${back_color}")
            fi
            prompt+="${arrow_color}${background_black}${reset}
${omg_second_line}"
        else
            prompt="${omg_ungit_prompt}"
        fi

        echo "${prompt}"
    }

    PS2="${yellow}→${reset} "

    source ${DIR}/base.sh
    function bash_prompt() {
        PS1="$(build_prompt)"
    }

    PROMPT_COMMAND=bash_prompt

fi
