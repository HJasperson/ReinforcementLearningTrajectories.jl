export ElasticArraySPLARTTraces

const ElasticArraySPLARTTraces = Traces{
    SS′PL′A′RT,
    <:Tuple{
        <:MultiplexTraces{SS′,<:Trace{<:ElasticArray}},
        <:Trace{<:ElasticArray},
        <:Trace{<:ElasticArray},
        <:Trace{<:ElasticArray},
        <:Trace{<:ElasticArray},
        <:Trace{<:ElasticArray},
    }
}

function ElasticArraySPLARTTraces(;
    capacity::Int,
    state=Int => (),
    legal_actions_mask=Bool => (),
    action=Int => (),
    action_log_prob=Float32 => (),
    reward=Float32 => (),
    terminal=Bool => ()
)
    state_eltype, state_size = state
    action_eltype, action_size = action
    action_log_prob_eltype, action_log_prob_size = action_log_prob
    legal_actions_mask_eltype, legal_actions_mask_size = legal_actions_mask
    reward_eltype, reward_size = reward
    terminal_eltype, terminal_size = terminal

    MultiplexTraces{SS′}(ElasticArray{state_eltype}(undef, state_size..., 0)) +
    Traces(
        action = ElasticArray{action_eltype}(undef, action_size..., 0),
        action_log_prob = ElasticArray{action_log_prob_eltype}(undef, action_log_prob_size..., 0),
        legal_actions_mask=ElasticArray{legal_actions_mask_eltype}(undef, legal_actions_mask_size..., 0),
        reward=ElasticArray{reward_eltype}(undef, reward_size..., 0),
        terminal=ElasticArray{terminal_eltype}(undef, terminal_size..., 0),        
    )
end
