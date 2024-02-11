defmodule NpmDeps.Downloader do
  @moduledoc """
  This module is responsible for downloading the NPM packages.
  """

  @registry "https://registry.npmjs.org"

  def get(namespace, version) when is_atom(namespace),
    do: get(to_string(namespace), version)

  def get(namespace, version) do
    {:ok, _} = Application.ensure_all_started(:req)

    name = namespace |> String.split("/") |> List.last()

    "#{@registry}/#{namespace}/-/#{name}-#{version}.tgz"
    |> fetch_files!()
    |> write_to_deps!(namespace)

    {:ok, {namespace, version}}
  end

  defp write_to_deps!(files, namespace) do
    package_path = Path.join(Mix.Project.deps_path(), namespace)
    File.mkdir_p!(package_path)

    for {path, contents} <- files do
      ["package" | path_parts] = Path.split(path)
      dest_path = Path.join([package_path | path_parts])
      dest_path |> Path.dirname() |> File.mkdir_p!()

      File.write!(dest_path, contents)
    end
  end

  defp fetch_files!(url) do
    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: files}} -> files
      error -> raise "Couldn't fetch #{url}: #{inspect(error)}"
    end
  end
end
