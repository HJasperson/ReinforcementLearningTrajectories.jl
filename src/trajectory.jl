export Trajectory, TrajectoryStyle, SyncTrajectoryStyle, AsyncTrajectoryStyle

using Base.Threads

struct AsyncTrajectoryStyle end
struct SyncTrajectoryStyle end

"""
    Trajectory(container, sampler, controller)

The `container` is used to store experiences. Common ones are [`Traces`](@ref)
or [`Episodes`](@ref). The `sampler` is used to sample experience batches from
the `container`. The `controller` controls whether it is time to sample a batch
or not.

Supported methoes are:

- `push!(t::Trajectory, experience)`, add one experience into the trajectory.
- `append!(t::Trajectory, batch)`, add a batch of experiences into the trajectory.
- `take!(t::Trajectory)`, take a batch of experiences from the trajectory. Note
  that `nothing` may be returned, indicating that it's not ready to sample yet.
"""
Base.@kwdef struct Trajectory{C,S,T}
    container::C
    sampler::S
    controller::T = InsertSampleRatioController()

    Trajectory(c::C, s::S, t::T=InsertSampleRatioController()) where {C,S,T} = new{C,S,T}(c, s, t)

    function Trajectory(container::C, sampler::S, controller::T) where {C,S,T<:AsyncInsertSampleRatioController}
        t = Threads.@spawn while true
            for msg in controller.ch_in
                if msg.f === Base.push!
                    x, = msg.args
                    msg.f(container, x)
                    controller.n_inserted += 1
                elseif msg.f === Base.append!
                    x, = msg.args
                    msg.f(container, x)
                    controller.n_inserted += length(x)
                else
                    msg.f(container, msg.args...; msg.kw...)
                end

                if controller.n_inserted >= controller.threshold
                    if controller.n_sampled <= (controller.n_inserted - controller.threshold) * controller.ratio
                        batch = sample(sampler, container)
                        put!(controller.ch_out, batch)
                        controller.n_sampled += 1
                    end
                end
            end
        end

        bind(controller.ch_in, t)
        bind(controller.ch_out, t)
        new{C,S,T}(container, sampler, controller)
    end
end

TrajectoryStyle(::Trajectory) = SyncTrajectoryStyle()
TrajectoryStyle(::Trajectory{<:Any,<:Any,<:AsyncInsertSampleRatioController}) = AsyncTrajectoryStyle()

Base.bind(::Trajectory, ::Task) = nothing

function Base.bind(t::Trajectory{<:Any,<:Any,<:AsyncInsertSampleRatioController}, task)
    bind(t.controler.ch_in, task)
    bind(t.controler.ch_out, task)
end

# !!! by default we assume `x`  is a complete example which contains all the traces
# When doing partial inserting, the result of undefined
function Base.push!(t::Trajectory, x)
    push!(t.container, x)
    on_insert!(t.controller, 1)
end

struct CallMsg
    f::Any
    args::Tuple
    kw::Any
end

Base.push!(t::Trajectory{<:Any,<:Any,<:AsyncInsertSampleRatioController}, x) = put!(t.controller.ch_in, CallMsg(Base.push!, (x,), NamedTuple()))
Base.append!(t::Trajectory{<:Any,<:Any,<:AsyncInsertSampleRatioController}, x) = put!(t.controller.ch_in, CallMsg(Base.append!, (x,), NamedTuple()))

function Base.append!(t::Trajectory, x)
    append!(t.container, x)
    on_insert!(t.controller, length(x))
end

# !!! bypass the controller
sample(t::Trajectory) = sample(t.sampler, t.container)

function Base.take!(t::Trajectory)
    res = on_sample!(t.controller)
    if isnothing(res)
        nothing
    else
        sample(t.sampler, t.container)
    end
end

function Base.iterate(t::Trajectory)
    x = take!(t)
    if isnothing(x)
        nothing
    else
        x, true
    end
end

Base.iterate(t::Trajectory, state) = iterate(t)

Base.iterate(t::Trajectory{<:Any,<:Any,<:AsyncInsertSampleRatioController}, args...) = iterate(t.controller.ch_out, args...)
Base.take!(t::Trajectory{<:Any,<:Any,<:AsyncInsertSampleRatioController}) = take!(t.controller.ch_out)

Base.IteratorSize(::Trajectory{<:Any,<:Any,<:AsyncInsertSampleRatioController}) = Base.IsInfinite()
Base.IteratorSize(::Trajectory) = Base.SizeUnknown()