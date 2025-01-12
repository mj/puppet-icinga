# frozen_string_literal: true

require 'spec_helper'

describe 'icinga::worker' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with ca_server => foo, zone => bar, parent_endpoints => { foobar => { host => 127.0.0.1}}, global_zones => [foobaz]' do
        let(:params) do
          {
            ca_server: 'foo',
            zone: 'bar',
            parent_endpoints: { 'foobar' => { 'host' => '127.0.0.1' } },
            global_zones: ['foobaz'],
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_class('icinga').with(
            {
              'ca'           => false,
              'ca_server'    => 'foo',
              'this_zone'    => 'bar',
              'zones'        => {
                'ZoneName' => {
                  'endpoints' => { 'NodeName' => {} },
                  'parent' => 'main',
                },
                'main' => {
                  'endpoints' => { 'foobar' => { 'host' => '127.0.0.1' } },
                },
              },
              'logging_type' => 'file',
            },
          )
        }

        it { is_expected.to contain_class('icinga2::feature::checker') }

        it { is_expected.to contain_icinga2__object__zone('foobaz').with({ 'global' => true }) }
      end
    end
  end
end
