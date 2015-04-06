FROM kuende/elixir:1.0.2

ADD . /app
WORKDIR /app

ENV MIX_ENV production
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile
RUN mix compile.protocols

EXPOSE 4000

ENTRYPOINT ["elixir", "-pa", "_build/prod/consolidated", "-S", "mix"]
CMD ["serve"]
