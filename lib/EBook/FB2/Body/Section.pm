# Copyright (c) 2009, 2010 Oleksandr Tymoshenko <gonzo@bluezbox.com>
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

package EBook::FB2::Body::Section;
use Moose;
use XML::DOM;

has id => ( isa => 'Str', is => 'rw' );
has title => ( isa => 'Ref', is => 'rw' );
has image => ( isa => 'Ref', is => 'rw' );
has data => ( isa => 'Ref', is => 'rw' );
has epigraph => ( 
    isa     => 'ArrayRef',
    is      => 'rw',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        epigraphs       => 'elements',
        add_epigraph    => 'push',
    },
);

has subsection => ( 
    isa     => 'ArrayRef',
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        subsections         => 'elements',
        add_subsection      => 'push',
    },
);

sub load
{
    my ($self, $node) = @_;

    my $anode = $node->getAttribute("id");
    if (defined($anode)) {
        $self->id($anode);
    }

    my @nodes = $node->findnodes("title");
    if (@nodes) {
        $self->title($nodes[0]);
        # separate title and main body
        foreach my $kid (@nodes) {
            $node->removeChild($kid);
        }
    }

    @nodes = $node->findnodes("epigraph");
    if (@nodes) {
        # separate epigraphs and main body
        foreach my $kid (@nodes) {
            $self->add_epigraph($kid);
            $node->removeChild($kid);
        }
    }

    @nodes = $node->findnodes("section");
    if (@nodes) {
        foreach my $n (@nodes) {
            my $s = EBook::FB2::Body::Section->new();
            $s->load($n);
            $self->add_subsection($s);
        }
    }
    # store raw XML::DOM::Node for collecting ids.
    $self->data($node);
}

#
# Extract plain text without formatting from XML::DOM node
#
sub extract_text
{
    my $node = shift;
    my $text;

    return $node->getData if ($node->getNodeType() == TEXT_NODE);

    # get text from children
    foreach my $kid ($node->getChildNodes) {
        $text .= extract_text($kid);
    }

    return $text;
}

sub plaintext_title
{
    my $self = shift;
    my $title = $self->title;
    my $section_title;
    if (defined($title)) {
        $section_title = extract_text($title);
        $section_title =~ s/\r?\n/ /g;
        # Cleanup extra-spaces
        while ($section_title =~ s/\s{2}/ /g) {
        }
        $section_title =~ s/^\s+//g;
        $section_title =~ s/\s+$//g;
    }

    return $section_title;
}

1;
