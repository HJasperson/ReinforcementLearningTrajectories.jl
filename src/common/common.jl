export SS′, LL′, AA′, RT, SS′ART, SS′AA′RT, SS′L′ART, SS′LL′AA′RT

const SS′ = (:state, :next_state)
const LL′ = (:legal_actions_mask, :next_legal_actions_mask)
const AA′ = (:action, :next_action)
const RT = (:reward, :terminal)
const SS′ART = (SS′..., :action, RT...)
const SS′AA′RT = (SS′..., AA′..., RT...)
const SS′L′ART = (SS′..., :next_legal_actions_mask, :action, RT...)
const SS′LL′AA′RT = (SS′..., LL′..., AA′..., RT...)

include("sum_tree.jl")
include("CircularArraySARTSTraces.jl")
include("CircularArraySARTSATraces.jl")
include("CircularArraySLARTTraces.jl")
include("CircularPrioritizedTraces.jl")
include("ElasticArraySARTSTraces.jl")
