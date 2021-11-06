.PHONY: help
help:
	@echo "Usage for libvirt-ocp4-provisioner:"
	@echo "    setup                    to install required collections"
	@echo "    create-ha                to create the cluster using HA setup"
	@echo "    create-sno               to create the cluster using Single Node setup"
	@echo "    destroy                  to destroy the cluster"
.PHONY: setup
setup:
	@ansible-galaxy collection install -r requirements.yml
.PHONY: create-ha
create-ha:
	@ansible-playbook main.yml
.PHONY: create-sno
create-sno:
	@ansible-playbook main-sno.yml -vv
.PHONY: destroy
destroy:
	@ansible-playbook 99_cleanup.yml
