# DO NOT EDIT. Generated with:
#
#    devctl
#
#    https://github.com/giantswarm/devctl/blob/eea19f200d7cfd27ded22474b787563bbfdb8ec4/pkg/gen/input/makefile/internal/file/Makefile.gen.app.mk.template
#

##@ App

YQ=docker run --rm -u $$(id -u) -v $${PWD}:/workdir mikefarah/yq:4.29.2
HELM_DOCS=docker run --rm -u $$(id -u) -v $${PWD}:/helm-docs jnorwood/helm-docs:v1.11.0
APPLICATION=helm/headlamp

.PHONY: lint-chart check-env update-chart helm-docs update-deps $(DEPS)

lint-chart: IMAGE := giantswarm/helm-chart-testing:v3.0.0-rc.1
lint-chart: check-env ## Runs ct against the default chart.
	@echo "====> $@"
	rm -rf /tmp/$(APPLICATION)-test
	mkdir -p /tmp/$(APPLICATION)-test/helm
	cp -a ./helm/$(APPLICATION) /tmp/$(APPLICATION)-test/helm/
	architect helm template --dir /tmp/$(APPLICATION)-test/helm/$(APPLICATION)
	docker run -it --rm -v /tmp/$(APPLICATION)-test:/wd --workdir=/wd --name ct $(IMAGE) ct lint --validate-maintainers=false --charts="helm/$(APPLICATION)"
	rm -rf /tmp/$(APPLICATION)-test

update-chart: bin/vendir ## Sync chart with upstream repo.
	@echo "====> $@"
	bin/vendir sync --yes
	$(MAKE) update-deps

update-deps:
	cd $(APPLICATION) && helm dependency update

$(DEPS):
	dep_name=$(shell basename $@) && \
	new_version=`$(YQ) .version $(APPLICATION)/charts/$$dep_name/Chart.yaml` && \
	$(YQ) -i e "with(.dependencies[]; select(.name == \"$$dep_name\") | .version = \"$$new_version\")" $(APPLICATION)/Chart.yaml

bin/vendir:
	mkdir -p bin
	wget --quiet https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.32.2/vendir-linux-amd64 -O bin/vendir
	echo "f5d3cbbd8135d2d48f4f007b8a933bd60b2a827d68f4001c5d1774392fa7b3f2  bin/vendir" | sha256sum -c -
	chmod +x bin/vendir

helm-docs:
	$(HELM_DOCS) -c $(APPLICATION) -g $(APPLICATION)
