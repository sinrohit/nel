# modules/toposort.nix
{ lib }:

with lib;

rec {
  # A basic topological sort implementation for activation scripts
  # Takes a function to get dependencies and a list of nodes
  toposort = getDeps: nodes:
    let
      # Convert list to graph representation
      nodeSet = listToAttrs (map (node: { name = node.name; value = node; }) nodes);

      # Helper function to visit nodes in DFS order
      visit = visited: visiting: result: node:
        let
          name = node.name;
        in
        if elem name visited then
          { inherit visited visiting result; }
        else if elem name visiting then
          throw "Cycle detected in activation scripts involving ${name}"
        else
          let
            # Mark this node as currently being visited
            newVisiting = [ name ] ++ visiting;

            # Process all dependencies first
            depsResult = foldl'
              (acc: dep:
                if acc.visited != [ ] && elem dep.name acc.visited then
                  acc
                else
                  visit acc.visited acc.newVisiting acc.result dep
              )
              { visited = [ ]; newVisiting = newVisiting; result = [ ]; }
              (getDeps node);

            # Mark this node as fully visited
            newVisited = [ name ] ++ depsResult.visited;

            # Add this node to the result after its dependencies
            newResult = [ node ] ++ depsResult.result;
          in
          {
            visited = newVisited;
            visiting = visiting;
            result = newResult;
          };

      # Visit all nodes
      result = foldl'
        (acc: node:
          if elem node.name acc.visited then
            acc
          else
            visit acc.visited acc.visiting acc.result node
        )
        { visited = [ ]; visiting = [ ]; result = [ ]; }
        nodes;
    in
    result.result;
}
