package stager;
use Moose::Role;
use Method::Signatures::Simple;

method preTargetCommit ($mode, $repodir, $message) {
    $self->logDebug("mode", $mode);
    $self->logDebug("repodir", $repodir);
    $self->logDebug("message", $message);

    my $sourcerepo = $self->sourcerepo();
    my $targetrepo = $self->targetrepo();
    $self->logDebug("sourcerepo", $sourcerepo);
    $self->logDebug("targetrepo", $targetrepo);
}
