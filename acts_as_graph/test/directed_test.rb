#--
# Copyright (c) 2007 Shawn Garbett
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice(s),
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the Shawn Garbett nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++
require File.join(File.dirname(__FILE__), 'test_helper')

class Node < ActiveRecord::Base
  acts_as_graph :graph, :in => :source, :out => :destination, :edges_class => 'NodeEdge'
end

class NodeEdge < ActiveRecord::Base
  set_table_name 'nodes_edges'
  belongs_to :source,      :class_name => 'Node', :foreign_key => 'source_id'
  belongs_to :destination, :class_name => 'Node', :foreign_key => 'destination_id'
end

class DirectedTest < Test::Unit::TestCase
  fixtures :nodes, :nodes_edges
  
  def test_vertices_must_return_all_vertices
    assert Node.count > 0
    assert_equal Node.find(:all).sort_by(&:id), Node.graph.vertices.sort_by(&:id)  
  end
  
  def test_vertex_must_return_true_if_in_table
    assert Node.graph.vertex?(Node.find(:first))
  end
  
  def test_vertex_must_return_false_unless_in_table
    assert !Node.graph.vertex?(Node.new)
  end
  
  def test_edges_must_return_all_edges
    assert_equal NodeEdge.count, Node.graph.edges.size
  end
  
  def test_edges_must_return_array_of_arcs
    Node.graph.edges.each {|e| assert e.is_a?(GRATR::Arc)}
  end
  
  def test_edges_must_return_array_of_arcs_with_source_object_set
    Node.graph.edges.each {|e| assert e.source.kind_of?(ActiveRecord::Base)}
  end
  
  def test_edges_must_return_array_of_arcs_with_destination_object_set
    Node.graph.edges.each {|e| assert e.target.kind_of?(ActiveRecord::Base)}
  end
  
  def test_edge_must_return_true_if_edge_in_graph_is_given
    assert Node.graph.edge?(GRATR::Arc[Node.find(2),Node.find(1)])
  end
  
  def test_edge_must_return_false_if_not_edge_in_graph_is_given
    assert !Node.graph.edge?(GRATR::Arc[Node.find(1),Node.find(2)])
  end
  
  def test_adjacent_out_must_return_all_children
    assert_equal [1], Node.graph.adjacent(Node.find(2), :direction => :out).map(&:id).sort
  end
  
  def test_adjacent_in_must_return_all_parents
    assert_equal [2,3], Node.graph.adjacent(Node.find(1), :direction => :in).map(&:id).sort
  end
  
  def test_adjacent_all_must_return_all_parents_and_children
    assert_equal [1,7], Node.graph.adjacent(Node.find(2), :direction => :all).map(&:id).sort
  end
  
  def test_adjacent_edges_in_must_return_all_in_edges
    assert_equal [7], Node.graph.adjacent(Node.find(2), :direction => :in, :type => :edges).map(&:source).map(&:id).sort
  end
  
  def test_adjacent_edges_in_must_return_arcs
    assert Node.graph.adjacent(Node.find(2), :direction => :in, :type => :edges).all? {|e| e.is_a? GRATR::Arc}
  end
  
  def test_adjacent_edges_out_must_return_all_out_edges
    assert_equal [1], Node.graph.adjacent(Node.find(2), :direction => :out, :type => :edges).map(&:target).map(&:id).sort
  end

  def test_adjacent_edges_out_must_return_arcs
    assert Node.graph.adjacent(Node.find(2), :direction => :out, :type => :edges).all? {|e| e.is_a? GRATR::Arc}
  end

  def test_adjacent_edges_all_must_return_all_parents_and_children
    assert_equal [[2,1],[7,2]],
                 Node.graph.adjacent(Node.find(2), :direction => :all, :type => :edges).map {|e| [e.source.id, e.target.id]}.sort
  end

  def test_adjacent_edges_all_must_return_arcs
    assert Node.graph.adjacent(Node.find(2), :direction => :all, :type => :edges).all? {|e| e.is_a? GRATR::Arc}
  end
  
  def test_adjacent_edges_out_must_return_arcs
    assert Node.graph.adjacent(Node.find(2), :direction => :out, :type => :edges).all? {|e| e.is_a? GRATR::Arc}
  end
  
  def test_sinks_must_return_nodes_with_no_children
    [1,4].map {|s| Node.find(s)}.each {|n| assert Node.graph.sinks.include?(n)}
    assert_equal 2, Node.graph.sinks.length
  end

  def test_sources_must_return_nodes_with_no_parents
    [3,7].map {|s| Node.find(s)}.each {|n| assert Node.graph.sources.include?(n)}
    assert_equal 2, Node.graph.sources.length
  end
  
end