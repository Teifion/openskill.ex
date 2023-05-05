defmodule Openskill.BradleyTerryFull do
  alias Openskill.{Environment, Util}

  @env %Environment{}

  def rate(game, options \\ %{:beta => @env.beta, :epsilon => @env.epsilon}) do
    twobetasq = 2 * options.beta * options.beta
    team_ratings = Util.team_rating(game)

    Enum.map(team_ratings, fn {teami_mu, teami_sigmasq, teami, ranki} ->
      {omegai, deltai} =
        team_ratings
        |> Enum.filter(fn {_, _, _, rankq} -> ranki != rankq end)
        |> Enum.reduce({0, 0}, fn {teamq_mu, teamq_sigmasq, _, rankq}, {omega, delta} ->
          ciq = Math.sqrt(teami_sigmasq + teamq_sigmasq + twobetasq)
          piq = 1 / (1 + Math.exp((teamq_mu - teami_mu) / ciq))
          sigsq_to_ciq = teami_sigmasq / ciq
          gamma = Math.sqrt(teami_sigmasq) / ciq

          {
            omega + sigsq_to_ciq * (Util.score(rankq, ranki) - piq),
            delta + gamma * sigsq_to_ciq / ciq * piq * (1 - piq)
          }
        end)

      for {muij, sigmaij} <- teami do
        sigmaijsq = sigmaij * sigmaij

        {
          muij + sigmaijsq / teami_sigmasq * omegai,
          sigmaij * Math.sqrt(max(1 - sigmaijsq / teami_sigmasq * deltai, options.epsilon))
        }
      end
    end)
  end
end
