# We don't want to use SCL since we are missing some dependencies 
# in SCL and we still support 1.8 for installer
%global scl_ruby /usr/bin/ruby

# set and uncomment all three to set alpha tag
#global alphatag RC1
#global dotalphatag .%{alphatag}
#global dashalphatag -%{alphatag}

Name:       fusor-installer
Epoch:      1
Version:    0.0.1
Release:    1%{?dotalphatag}%{?dist}
Summary:    Foreman-installer plugin that allows you to install Fusor
Group:      Applications/System
License:    GPLv3+ and ASL 2.0
URL:        http://theforeman.org
Source0:    %{name}-%{version}%{?dashalphatag}.tar.gz

BuildArch:  noarch

Requires:   katello-installer
Requires:   ntp
Requires:   rubygem-kafo >= 0.6.4
Requires:   rubygem-foreman_api >= 0.1.4
Requires:   git

%if 0%{?fedora} > 18
Requires:   %{?scl_prefix}ruby(release)
%else
Requires:   %{?scl_prefix}ruby(abi)
%endif

%description
This is a Foreman-Installer plugin that allows you to install and configure
the Fusor Foreman plugin

%prep
%setup -q -n %{name}-%{version}%{?dashalphatag}

%build
#replace shebangs for SCL
%if %{?scl:1}%{!?scl:0}
  sed -ri '1sX(/usr/bin/ruby|/usr/bin/env ruby)X%{scl_ruby}X' bin/fusor-installer
%endif

%install
install -d -m0755 %{buildroot}%{_datadir}/katello-installer
cp -R hooks modules %{buildroot}%{_datadir}/katello-installer
install -d -m0755 %{buildroot}%{_sbindir}
cp bin/fusor-installer %{buildroot}%{_sbindir}/fusor-installer
install -d -m0755 %{buildroot}%{_bindir}
cp bin/fusor-register-host %{buildroot}%{_bindir}/fusor-register-host
install -d -m0755 %{buildroot}%{_sysconfdir}/katello-installer/
cp config/fusor-installer.yaml %{buildroot}%{_sysconfdir}/katello-installer/fusor-installer.yaml
cp config/fusor-installer.answers.yaml %{buildroot}%{_sysconfdir}/katello-installer/fusor-installer.answers.yaml


%files
%defattr(-,root,root,-)
%doc LICENSE
%{_datadir}/katello-installer/hooks/boot/10-add_options.rb
%{_datadir}/katello-installer/hooks/lib/base_seeder.rb
%{_datadir}/katello-installer/hooks/lib/foreman.rb
%attr(755, root, root) %{_datadir}/katello-installer/hooks/lib/install_modules.sh
%{_datadir}/katello-installer/hooks/lib/base_wizard.rb
%{_datadir}/katello-installer/hooks/lib/provisioning_seeder.rb
%{_datadir}/katello-installer/hooks/lib/provisioning_wizard.rb
%{_datadir}/katello-installer/hooks/post/10-setup_provisioning.rb
%{_datadir}/katello-installer/hooks/pre_validations/10-gather_and_set_fusor_values.rb
%{_datadir}/katello-installer/hooks/pre_values/10-register_fusor_modules.rb
%{_datadir}/katello-installer/modules/network
%{_datadir}/katello-installer/modules/foreman/manifests/plugin/fusor.pp
%{_datadir}/katello-installer/modules/foreman/manifests/plugin/fusor_network.pp

%config %attr(600, root, root) %{_sysconfdir}/katello-installer/fusor-installer.yaml
%config(noreplace) %attr(600, root, root) %{_sysconfdir}/katello-installer/fusor-installer.answers.yaml
%{_sbindir}/fusor-installer
%{_bindir}/fusor-register-host

%changelog


